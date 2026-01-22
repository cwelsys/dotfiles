"""Custom tab bar renderer for kitty terminal.

This module provides two tab bar styles:
  - "pills": Three-zone layout (left cwd, center tabs, right status)
  - "powerline": Same as kitty's built-in but with fluff

Files:
  - tabbar.toml         : User configuration (create from tabbar.toml.example)
  - tabbar.toml.example : Reference documentation with all options and defaults
  - tabbar_config.py    : Config parsing, validation, color resolution
  - tab_bar.py          : Rendering logic (this file)

Configuration is loaded from ~/.config/kitty/tabbar.toml via tabbar_config.py.

Kitty calls draw_tab() for each tab, twice per render:
  1. for_layout=True  → Return estimated width (don't do expensive work)
  2. for_layout=False → Actually draw to screen

Color formatting uses kitty's Formatter class:
  - {fmt.fg.tab}      → Tab's assigned fg color
  - {fmt.fg._RRGGBB}  → Arbitrary hex (note underscore prefix!)
  - {fmt.fg.color5}   → Terminal palette color
"""

import os
import subprocess
import sys
from dataclasses import dataclass, field
from pathlib import Path

# Add config directory to path for local imports
_config_dir = Path.home() / ".config" / "kitty"
if str(_config_dir) not in sys.path:
    sys.path.insert(0, str(_config_dir))

from kitty.boss import get_boss
from kitty.fast_data_types import Screen
from kitty.tab_bar import (
    DrawData,
    ExtraData,
    TabBarData,
    draw_tab_with_powerline,
)

from tabbar_config import (
    UnifiedColorResolver,
    get_active_style,
    get_color_resolver,
    get_config,
    get_icon,
)


@dataclass
class TabInfo:
    """Unified tab information used by all styles."""

    tab: TabBarData
    index: int
    exe: str
    cwd: str
    icon: str
    hostname: str | None
    is_active: bool
    is_pinned: bool = False

    @property
    def is_remote(self) -> bool:
        return bool(self.hostname)


_home = os.path.expanduser("~")
_SHELLS = {"zsh", "bash", "fish", "sh", "nu", "tcsh", "-zsh", "-bash"}

# Git status cache: repo_path -> ((index_mtime, stash_mtime), (branch, counts))
_git_cache: dict[str, tuple[tuple[float, float], tuple[str, dict[str, int]]]] = {}


def _find_git_dir(cwd: str) -> Path | None:
    """Walk up from cwd to find .git directory.

    Handles both regular repos (.git is a directory) and worktrees
    (.git is a file pointing to the main repo's git dir).
    """
    try:
        path = Path(cwd)
        for parent in [path, *path.parents]:
            git_path = parent / ".git"
            if git_path.is_dir():
                return git_path
            if git_path.is_file():
                # Worktree: .git is a file containing "gitdir: /path/to/git"
                content = git_path.read_text().strip()
                if content.startswith("gitdir:"):
                    return Path(content[7:].strip())
        return None
    except Exception:
        return None


def _parse_git_output(raw: str) -> tuple[str, dict[str, int]]:
    """Parse git status --porcelain=v2 --branch output.

    Returns:
        (branch_name, {ahead, behind, staged, modified, deleted, renamed, untracked, conflicted})

    XY codes in porcelain v2:
        X = staged status, Y = worktree status
        M = modified, A = added, D = deleted, R = renamed, C = copied
        . = unchanged, ? = untracked, ! = ignored
    """
    branch = ""
    counts = {
        "ahead": 0,
        "behind": 0,
        "staged": 0,
        "modified": 0,
        "deleted": 0,
        "renamed": 0,
        "untracked": 0,
        "conflicted": 0,
    }

    for line in raw.splitlines():
        if line.startswith("# branch.head "):
            branch = line.split()[-1]
        elif line.startswith("# branch.ab "):
            # Format: # branch.ab +N -M
            parts = line.split()
            if len(parts) >= 4:
                counts["ahead"] = int(parts[2].lstrip("+"))
                counts["behind"] = abs(int(parts[3]))
        elif line.startswith("2 "):
            # Renamed/copied entries (type 2)
            counts["renamed"] += 1
        elif line.startswith("1 "):
            # Changed entries: 1 XY ...
            parts = line.split()
            if len(parts) >= 2:
                xy = parts[1]
                if len(xy) >= 2:
                    # Check staged (X position)
                    if xy[0] == "D":
                        counts["deleted"] += 1
                    elif xy[0] not in (".", "?"):
                        counts["staged"] += 1
                    # Check worktree (Y position)
                    if xy[1] == "D":
                        counts["deleted"] += 1
                    elif xy[1] not in (".", "?"):
                        counts["modified"] += 1
        elif line.startswith("u "):
            # Unmerged/conflicted
            counts["conflicted"] += 1
        elif line.startswith("? "):
            # Untracked
            counts["untracked"] += 1

    return branch, counts


# Git branch icon (nf-md-source_branch U+E725)
_GIT_BRANCH_ICON = "\ue725"


def _format_git_parts(
    branch: str, counts: dict[str, int], branch_only: bool = False
) -> list[tuple[str, str]]:
    """Format git info into (text, part_type) tuples for colorization.

    Args:
        branch: Branch name
        counts: Status counts dict
        branch_only: If True, only return branch icon + name (no status)

    Returns list compatible with _draw_git_pill's expected format.
    """
    parts: list[tuple[str, str]] = []

    # Git branch icon with space
    parts.append((_GIT_BRANCH_ICON + " ", "git_branch_icon"))

    # Branch name
    parts.append((branch, "git_branch"))

    if branch_only:
        return parts

    # Status symbols (order matches starship convention)
    symbols = [
        ("stashed", "*"),
        ("deleted", "✘"),
        ("staged", "+"),
        ("modified", "!"),
        ("renamed", "»"),
        ("untracked", "?"),
        ("conflicted", "~"),
        ("ahead", "⇡"),
        ("behind", "⇣"),
    ]

    status_parts = []
    for key, sym in symbols:
        if counts.get(key, 0) > 0:
            status_parts.append((f"{sym}{counts[key]}", f"git_{key}"))

    if status_parts:
        parts.append((" ", "git_branch"))  # Separator
        for i, (text, part_type) in enumerate(status_parts):
            if i > 0:
                parts.append((" ", "git_branch"))  # Space between status items
            parts.append((text, part_type))

    return parts


def _get_git_parts_length(parts: list[tuple[str, str]]) -> int:
    """Get the display length of git parts."""
    return sum(len(text) for text, _ in parts)


def _get_git_status_raw(cwd: str) -> tuple[str, dict[str, int]] | None:
    """Get git status for cwd, mtime-gated.

    Returns (branch, counts) tuple for flexible formatting,
    or None if not in a git repo or on error.
    """
    git_dir = _find_git_dir(cwd)
    if not git_dir:
        return None

    # Check index mtime for cache invalidation
    index = git_dir / "index"
    try:
        current_mtime = index.stat().st_mtime if index.exists() else 0
    except Exception:
        current_mtime = 0

    # Also check stash refs mtime (changes when stash is modified)
    stash_ref = git_dir / "refs" / "stash"
    try:
        stash_mtime = stash_ref.stat().st_mtime if stash_ref.exists() else 0
    except Exception:
        stash_mtime = 0

    # Combine mtimes for cache key
    combined_mtime = (current_mtime, stash_mtime)
    repo_key = str(git_dir.parent) if git_dir.name == ".git" else str(git_dir)

    # Check cache
    if repo_key in _git_cache:
        cached_mtime, cached_data = _git_cache[repo_key]
        if cached_mtime == combined_mtime:
            return cached_data

    # Cache miss - run git status
    try:
        result = subprocess.run(
            ["git", "-C", cwd, "status", "--porcelain=v2", "--branch"],
            capture_output=True,
            text=True,
            timeout=0.5,
        )
        if result.returncode != 0:
            return None

        branch, counts = _parse_git_output(result.stdout)
        if not branch:
            return None

        # Get stash count (separate command, but only if stash ref exists)
        if stash_ref.exists():
            try:
                stash_result = subprocess.run(
                    ["git", "-C", cwd, "stash", "list"],
                    capture_output=True,
                    text=True,
                    timeout=0.3,
                )
                if stash_result.returncode == 0:
                    stash_lines = stash_result.stdout.strip().splitlines()
                    counts["stashed"] = len(stash_lines)
            except Exception:
                pass  # Stash count is optional

        _git_cache[repo_key] = (combined_mtime, (branch, counts))
        return (branch, counts)
    except Exception:
        return None


@dataclass
class RenderContext:
    """Render context holding all state for a single render cycle.

    This replaces multiple global variables with a single context object
    that's passed through the render pipeline. The context is created at
    the start of each render cycle and reset at the end.

    Attributes:
        colors: UnifiedColorResolver for color resolution with live theme support
        config: TabBarConfig for access to all configuration
        tabs: List of TabInfo for all tabs (pills style collects these)
        active_tab_index: Index of the active tab in the tabs list
        cached_tab_positions: End positions keyed by tab_id (survives reorder)
        screen_columns: Total screen width for layout calculations
    """

    colors: UnifiedColorResolver
    config: "TabBarConfig"  # Forward reference to avoid circular import
    tabs: list[TabInfo] = field(default_factory=list)
    active_tab_index: int = 0
    cached_tab_positions: dict[int, int] = field(default_factory=dict)  # tab_id -> end_pos
    screen_columns: int = 0


# Global render context (set per render cycle)
_render_ctx: RenderContext | None = None


def _color_int(name: str) -> int:
    """Convert color name to RGB int for screen.cursor.

    Uses the current render cycle's context for live theme colors.
    Falls back to static config resolver outside render cycle.
    """
    if _render_ctx is not None:
        return _render_ctx.colors.resolve_to_int(name)
    return get_color_resolver().as_int(name)


def _c(name: str) -> str:
    """Resolve color name to hex value for formatting strings.

    Returns hex without # prefix for use in {fmt.fg._RRGGBB} patterns.
    Uses the current render cycle's context for live theme colors.
    """
    if _render_ctx is not None:
        return _render_ctx.colors.resolve_to_hex(name)
    return get_color_resolver().resolve(name)


def get_path_parts(cwd: str, max_segments: int) -> tuple[str, ...]:
    """Get path as tuple of parts, shortened for display."""
    if cwd.startswith(_home):
        cwd = "~" + cwd[len(_home) :]

    parts = cwd.strip("/").split("/")
    if len(parts) > max_segments:
        parts = [".."] + parts[-max_segments:]

    return tuple(parts)


def colorize_parts(
    parts: tuple[str, ...],
    sep: str,
    tab_index: int,
    is_active: bool,
    colors_cfg,
) -> str:
    """Colorize segments with rainbow colors."""
    colored_parts = []
    num_parts = len(parts)

    for i, part in enumerate(parts):
        is_last = i == num_parts - 1

        if is_active:
            color = _c(colors_cfg.path_active_main)
        else:
            color_idx = (tab_index + i) % len(colors_cfg.rainbow)
            color = _c(colors_cfg.rainbow[color_idx])

        colored_parts.append(f"{{fmt.fg._{color}}}{part}")

    colored_sep = f"{{fmt.fg.tab}}{sep}"
    return colored_sep.join(colored_parts) + "{fmt.fg.tab}"


TITLE_SEPARATORS = ["/", " - ", ": ", " | "]


def colorize_title(text: str, tab_index: int, is_active: bool, config) -> str:
    """Colorize any title by splitting on common separators."""
    powerline = config.styles.powerline
    if not powerline.rainbow_path:
        return text

    colors_cfg = powerline.colors
    for sep in TITLE_SEPARATORS:
        if sep in text:
            parts = tuple(text.split(sep))
            return colorize_parts(parts, sep, tab_index, is_active, colors_cfg)

    if is_active:
        color = _c(colors_cfg.path_active_main)
    else:
        color_idx = tab_index % len(colors_cfg.rainbow)
        color = _c(colors_cfg.rainbow[color_idx])
    return f"{{fmt.fg._{color}}}{text}{{fmt.fg.tab}}"


def format_path(cwd: str, index: int, is_active: bool, config) -> str:
    """Format path, optionally with rainbow colors."""
    powerline = config.styles.powerline
    parts = get_path_parts(cwd, powerline.max_path_segments)
    if powerline.rainbow_path:
        return colorize_parts(parts, "/", index, is_active, powerline.colors)
    return "/".join(parts)


def get_foreground_process(tab_id: int) -> tuple[str, str, str | None]:
    """Get the foreground process name, cwd, and optional remote host.

    Uses TabAccessor (kitty's safe API) instead of direct process scanning.

    Returns:
        Tuple of (executable_name, current_working_directory, remote_hostname).
        Falls back to ("zsh", "", None) on errors.
    """
    try:
        from kitty.tab_bar import TabAccessor

        ta = TabAccessor(tab_id)

        # Use TabAccessor's safe methods
        exe = ta.active_exe or "zsh"
        cwd = ta.active_wd or ""

        # Check user vars for process, remote cwd, and remote host (shell hooks)
        remote_host = None
        try:
            boss = get_boss()
            tab = boss.tab_for_id(tab_id)
            if tab and tab.active_window:
                # PROC user var overrides exe (for SSH and shell hooks)
                proc = tab.active_window.user_vars.get("PROC")
                if proc and proc not in _SHELLS:
                    exe = proc
                # REMOTE_CWD overrides cwd for SSH sessions
                remote_cwd = tab.active_window.user_vars.get("REMOTE_CWD")
                if remote_cwd:
                    cwd = remote_cwd
                remote_host = tab.active_window.user_vars.get("REMOTE_HOST") or None
        except Exception as e:
            print(
                f"[tab_bar] Warning: Failed to get user vars for tab {tab_id}: {e}",
                file=sys.stderr,
            )

        return (exe, cwd, remote_host)
    except Exception as e:
        print(
            f"[tab_bar] Warning: Failed to get foreground process for tab {tab_id}: {e}",
            file=sys.stderr,
        )
        return ("zsh", "", None)


def get_tab_info(tab: TabBarData, index: int) -> TabInfo:
    """Create a TabInfo with all relevant data for rendering."""
    exe, cwd, hostname = get_foreground_process(tab.tab_id)
    icon = get_icon(exe)
    return TabInfo(
        tab=tab,
        index=index,
        exe=exe,
        cwd=cwd,
        icon=icon,
        hostname=hostname,
        is_active=tab.is_active,
    )


def format_tab_title(
    exe: str,
    cwd: str,
    title: str,
    index: int,
    is_active: bool,
    remote_host: str | None,
    config,
) -> str:
    """Format tab title based on powerline elements config."""
    powerline = config.styles.powerline
    colors_cfg = powerline.colors  # Use new canonical location

    parts = []
    if is_active:
        icon_color = _c(colors_cfg.icon_active)
    elif powerline.rainbow_index_icon:
        icon_color = _c(colors_cfg.rainbow[(index - 1) % len(colors_cfg.rainbow)])
    else:
        icon_color = _c(colors_cfg.icon_inactive)

    for element in powerline.elements:
        if element == "index":
            parts.append(f"{{fmt.fg._{icon_color}}}{index}{{fmt.fg.tab}}")
        elif element == "icon":
            icon = get_icon(exe)
            parts.append(f"{{fmt.fg._{icon_color}}}{icon}{{fmt.fg.tab}}")
        elif element == "name":
            parts.append(exe)
        elif element == "path":
            display = title or cwd
            if display:
                if display.startswith(("~", "/", ".", "…")):
                    parts.append(format_path(display, index, is_active, config))
                else:
                    parts.append(colorize_title(display, index, is_active, config))
        elif element == "ssh" and remote_host:
            parts.append(f"{{fmt.fg._{icon_color}}}{powerline.ssh_icon}{{fmt.fg.tab}}")
        elif element == "hostname" and remote_host:
            parts.append(f"{{fmt.fg._{icon_color}}}{remote_host}{{fmt.fg.tab}}")

    content = powerline.element_sep.join(parts)
    result = f"{powerline.pad_start}{content}{powerline.pad_end}"
    return result


def get_keyboard_mode() -> str:
    """Get the current keyboard mode name, empty string if normal."""
    try:
        mode = get_boss().mappings.current_keyboard_mode_name
        return mode if mode else ""
    except Exception:
        return ""


def _draw_pill(
    screen: Screen,
    icon: str,
    text: str | None,
    icon_bg: int,
    text_bg: int,
    icon_fg: int,
    text_fg: int,
    pills,
) -> None:
    """Draw a single pill with icon and optional text."""
    # Left border
    screen.cursor.bg = 0
    screen.cursor.fg = icon_bg
    screen.draw(pills.border_left)

    # Icon section (with trailing padding)
    screen.cursor.bg = icon_bg
    screen.cursor.fg = icon_fg
    screen.cursor.bold = True
    screen.draw(f"{icon} ")
    screen.cursor.bold = False

    if text:
        # Separator (transition from icon_bg to text_bg)
        screen.cursor.bg = text_bg
        screen.cursor.fg = icon_bg
        screen.draw(pills.separator)

        # Text section
        screen.cursor.fg = text_fg
        screen.draw(f" {text}")

        # Right border
        screen.cursor.fg = text_bg
        screen.cursor.bg = 0
        screen.draw(pills.border_right)
    else:
        # No text - close directly after icon
        screen.cursor.bg = 0
        screen.cursor.fg = icon_bg
        screen.draw(pills.border_right)


def _pill_width(icon: str, text: str | None) -> int:
    """Calculate drawn width of a pill."""
    width = 2 + len(icon) + 1  # left_border(1) + icon + padding(1) + right_border(1)
    if text:
        width += 1 + 1 + len(text)  # separator(1) + space(1) + text
    return width


def _draw_git_pill(
    screen: Screen,
    icon: str,
    git_parts: list[tuple[str, str]],
    icon_bg: int,
    text_bg: int,
    icon_fg: int,
    git_colors,
    pills,
) -> None:
    """Draw a pill with colorized git status text.

    Args:
        git_parts: List of (text, part_type) from _get_git_status or _format_git_parts
        git_colors: GitColorsConfig with color names for each part type
    """
    # Left border
    screen.cursor.bg = 0
    screen.cursor.fg = icon_bg
    screen.draw(pills.border_left)

    # Icon section
    screen.cursor.bg = icon_bg
    screen.cursor.fg = icon_fg
    screen.cursor.bold = True
    screen.draw(f"{icon} ")
    screen.cursor.bold = False

    if git_parts:
        # Separator
        screen.cursor.bg = text_bg
        screen.cursor.fg = icon_bg
        screen.draw(pills.separator)

        # Draw each part with its color
        screen.draw(" ")  # Leading space in text section
        for text, part_type in git_parts:
            color_name = getattr(git_colors, part_type, "foreground")
            screen.cursor.fg = _color_int(color_name)
            screen.draw(text)

        # Right border
        screen.cursor.fg = text_bg
        screen.cursor.bg = 0
        screen.draw(pills.border_right)
    else:
        # No text - close directly after icon
        screen.cursor.bg = 0
        screen.cursor.fg = icon_bg
        screen.draw(pills.border_right)


def _abbreviate_path(cwd: str, max_len: int) -> str | None:
    """Abbreviate path segments: ~/.lo/sh/chezmoi/home style.

    Shortens intermediate segments to 2 chars (or 3 for dotfiles),
    keeps last segment full.
    """
    if not cwd:
        return None

    if cwd.startswith(_home):
        cwd = "~" + cwd[len(_home):]

    if len(cwd) <= max_len:
        return cwd

    parts = cwd.split("/")
    if len(parts) <= 1:
        return cwd if len(cwd) <= max_len else None

    # Abbreviate all but last segment
    abbreviated = []
    for i, part in enumerate(parts[:-1]):
        if part == "~" or part == "":
            abbreviated.append(part)
        elif part.startswith("."):
            # Dotfiles: keep dot + 2 chars (e.g., .config -> .co)
            abbreviated.append(part[:3] if len(part) > 3 else part)
        else:
            # Regular: 2 chars (e.g., share -> sh)
            abbreviated.append(part[:2] if len(part) > 2 else part)

    # Add last segment full
    abbreviated.append(parts[-1])
    result = "/".join(abbreviated)

    if len(result) <= max_len:
        return result

    # Still too long - try just last segment
    if len(parts[-1]) <= max_len:
        return parts[-1]

    # Truncate last segment
    if max_len > 3:
        return parts[-1][:max_len - 1] + "…"

    return None


def _get_cwd_display(cwd: str, max_len: int, max_segments: int) -> str | None:
    """Get cwd formatted for display, respecting max length.

    Uses abbreviated style: ~/.lo/sh/repo/subdir
    """
    if not cwd or max_len <= 0:
        return None

    return _abbreviate_path(cwd, max_len)


def _format_pill_icon(info: TabInfo, pills, display_index: int | None = None) -> str:
    """Format the icon section content for a pill.

    Args:
        info: Tab information
        pills: Pills config
        display_index: Index to display (None = omit index, for pinned tabs)
    """
    parts = []
    for element in pills.icon_elements:
        if element == "index" and display_index is not None:
            parts.append(str(display_index))
        elif element == "icon":
            parts.append(info.icon)
    return (
        " ".join(parts)
        if parts
        else (str(display_index) if display_index is not None else info.icon)
    )


def _format_pill_text(info: TabInfo, pills) -> str:
    """Format the text section content for a pill."""
    parts = []
    for element in pills.text_elements:
        if element == "name":
            parts.append(info.exe)
        elif element == "title":
            if info.tab.title:
                parts.append(info.tab.title)
        elif element == "path":
            display = info.tab.title or info.cwd
            if display:
                # Use pills-specific max_path_segments from left_zone config
                path_parts = (
                    get_path_parts(display, pills.left_zone.max_path_segments)
                    if display.startswith(("~", "/", ".", "…"))
                    else (display,)
                )
                parts.append("/".join(path_parts))
        elif element == "hostname" and info.hostname:
            parts.append(info.hostname)
    return " ".join(parts)


def draw_tab_pills(
    draw_data: DrawData,
    screen: Screen,
    tab: TabBarData,
    before: int,
    max_title_length: int,
    index: int,
    is_last: bool,
    extra_data: ExtraData,
) -> int:
    """Draw tabs using pill/tag style with three-zone layout.

    Layout: [LEFT: cwd pill] [CENTER: tab pills] [RIGHT: mode indicator]

    Kitty calls this function twice per render cycle:
      1. Layout phase (for_layout=True): Return estimated width quickly.
         Don't do expensive work - kitty uses this to calculate positions.
      2. Render phase (for_layout=False): Actually draw to screen.
         All tabs are collected, then drawn on is_last=True.

    The pills style collects all tab info during render, then draws everything
    on the last tab to enable centering and responsive layout strategies.
    """
    global _render_ctx

    # Layout phase: return cached positions from previous render if available
    # Must set cursor.x because kitty uses it for width calculation
    if extra_data.for_layout:
        if _render_ctx is not None and tab.tab_id in _render_ctx.cached_tab_positions:
            screen.cursor.x = _render_ctx.cached_tab_positions[tab.tab_id]
            return screen.cursor.x
        # Fallback: simple estimation
        screen.cursor.x = before + 15
        return screen.cursor.x

    # Initialize or get render context
    config = get_config()
    if _render_ctx is None:
        # First ever render - create fresh context
        _render_ctx = RenderContext(
            colors=UnifiedColorResolver(config, draw_data),
            config=config,
            screen_columns=screen.columns,
        )
    elif index == 1:
        # New render cycle - preserve cached_tab_positions for click tracking
        old_cached = _render_ctx.cached_tab_positions
        _render_ctx = RenderContext(
            colors=UnifiedColorResolver(config, draw_data),
            config=config,
            screen_columns=screen.columns,
        )
        _render_ctx.cached_tab_positions = old_cached

    pills = config.styles.pills

    # Collect tab info
    info = get_tab_info(tab, index)
    # Check if tab should be pinned to right zone
    if pills.right_zone.enabled:
        # Check PINNED user var first (explicit pinning via kitten)
        try:
            boss = get_boss()
            kitty_tab = boss.tab_for_id(tab.tab_id)
            if kitty_tab and kitty_tab.active_window:
                if kitty_tab.active_window.user_vars.get("PINNED") == "true":
                    info.is_pinned = True
        except Exception:
            pass
        # Also check process name (auto-detection)
        if not info.is_pinned and info.exe in pills.right_zone.pinned_processes:
            info.is_pinned = True
    _render_ctx.tabs.append(info)
    if info.is_active:
        _render_ctx.active_tab_index = len(_render_ctx.tabs) - 1

    # If not the last tab, return cached position or estimate
    if not is_last:
        if info.tab.tab_id in _render_ctx.cached_tab_positions:
            return _render_ctx.cached_tab_positions[info.tab.tab_id]
        return before + 15

    # === Last tab: draw everything ===
    tabs = _render_ctx.tabs
    active_idx = _render_ctx.active_tab_index
    active_info = tabs[active_idx] if tabs else info
    n_tabs = len(tabs)

    # Split tabs into center and right (pinned) zones, preserving original indices
    center_tabs: list[tuple[int, TabInfo]] = []
    right_tabs: list[tuple[int, TabInfo]] = []
    for orig_idx, t in enumerate(tabs):
        if t.is_pinned:
            right_tabs.append((orig_idx, t))
        else:
            center_tabs.append((orig_idx, t))

    # Find active tab index within center_tabs (for expand_active strategy)
    center_active_idx: int | None = None
    for idx, (_, t) in enumerate(center_tabs):
        if t.is_active:
            center_active_idx = idx
            break

    # Width calculation helpers
    def tab_width_expanded(ti: TabInfo, display_index: int | None = 1) -> int:
        return _pill_width(
            _format_pill_icon(ti, pills, display_index), _format_pill_text(ti, pills)
        )

    def tab_width_collapsed(ti: TabInfo, display_index: int | None = 1) -> int:
        return _pill_width(_format_pill_icon(ti, pills, display_index), None)

    # Calculate center zone widths (only non-pinned tabs)
    n_center = len(center_tabs)
    center_spacing = (n_center - 1) * pills.spacing if n_center > 1 else 0
    center_all_expanded = (
        sum(tab_width_expanded(t) for _, t in center_tabs) + center_spacing
    )
    center_active_expanded = (
        (
            sum(
                tab_width_expanded(t)
                if i == center_active_idx
                else tab_width_collapsed(t)
                for i, (_, t) in enumerate(center_tabs)
            )
            + center_spacing
        )
        if center_tabs
        else 0
    )
    center_all_collapsed = (
        sum(tab_width_collapsed(t) for _, t in center_tabs) + center_spacing
    )

    # Calculate right zone width (pinned tabs - always expanded, no index)
    n_right = len(right_tabs)
    right_spacing = (n_right - 1) * pills.spacing if n_right > 1 else 0
    right_width = (
        sum(tab_width_expanded(t, display_index=None) for _, t in right_tabs)
        + right_spacing
    )

    # Reserve space for right zone
    right_margin = 2  # Gap between center and right zones
    available_for_center = (
        screen.columns - right_width - right_margin if right_tabs else screen.columns
    )

    # Determine strategy for center zone
    max_center = int(available_for_center * 0.6)

    if center_all_expanded <= max_center:
        strategy = "expand_all"
        center_width = center_all_expanded
    elif center_active_expanded <= max_center:
        strategy = "expand_active"
        center_width = center_active_expanded
    else:
        strategy = "collapse_all"
        center_width = center_all_collapsed

    # Calculate positions - center tabs on screen, adjust if overlapping right zone
    center_start = (screen.columns - center_width) // 2

    # Ensure tabs don't overlap with right zone
    if right_tabs:
        max_center_end = screen.columns - right_width - right_margin
        if center_start + center_width > max_center_end:
            center_start = max(0, max_center_end - center_width)

    # Left zone gets space before center tabs
    left_max = center_start - 2 if pills.left_zone.enabled else 0

    # === Draw Left Zone (folder + cwd, or mode indicator + cwd) ===
    if pills.left_zone.enabled and left_max > 10:
        mode_cfg = config.mode_indicator
        mode = get_keyboard_mode()

        # Check if mode indicator should be shown (highest priority)
        if mode and mode_cfg.enabled:
            # Mode active: swap icon and colors
            left_icon = mode_cfg.display_names.get(mode, mode.upper())
            icon_bg = _color_int(mode_cfg.pills.icon_bg)
            icon_fg = (
                _color_int(mode_cfg.pills.icon_fg)
                if mode_cfg.pills.icon_fg
                else _color_int(pills.colors.icon_fg_active)
            )
        elif active_info.is_remote:
            # SSH: show remote icon
            left_icon = pills.left_zone.ssh_icon
            icon_bg = _color_int(pills.colors.icon_bg_active)
            icon_fg = _color_int(pills.colors.icon_fg_active)
        else:
            # Normal: folder icon
            left_icon = pills.left_zone.icon
            icon_bg = _color_int(pills.colors.icon_bg_active)
            icon_fg = _color_int(pills.colors.icon_fg_active)

        text_bg = _color_int(pills.colors.text_bg_active)
        text_fg = _color_int(pills.colors.text_fg_active)

        max_text_len = left_max - _pill_width(left_icon, "") - 3

        # Get git status if enabled (mtime-gated)
        git_data = None
        if pills.left_zone.use_git and active_info.cwd:
            git_data = _get_git_status_raw(active_info.cwd)

        if git_data:
            branch, counts = git_data

            # Progressive collapse levels:
            # 1. abbrev_cwd + full_git:  ~/.co/ki  main +3 !2 ⇣1
            # 2. git only (full):         main +3 !2 ⇣1
            # 3. git branch only:         main

            git_full = _format_git_parts(branch, counts, branch_only=False)
            git_branch_only = _format_git_parts(branch, counts, branch_only=True)
            git_full_len = _get_git_parts_length(git_full)
            git_branch_len = _get_git_parts_length(git_branch_only)

            # Try: abbrev_cwd + full_git
            cwd_text = _abbreviate_path(active_info.cwd, max_text_len - git_full_len - 1)
            if cwd_text and len(cwd_text) + 1 + git_full_len <= max_text_len:
                display_parts: list[tuple[str, str]] = [(cwd_text + " ", "directory")]
                display_parts.extend(git_full)
                _draw_git_pill(
                    screen, left_icon, display_parts, icon_bg, text_bg, icon_fg,
                    pills.left_zone.git_colors, pills,
                )
            # Try: git full only (no cwd)
            elif git_full_len <= max_text_len:
                _draw_git_pill(
                    screen, left_icon, git_full, icon_bg, text_bg, icon_fg,
                    pills.left_zone.git_colors, pills,
                )
            # Try: git branch only
            elif git_branch_len <= max_text_len:
                _draw_git_pill(
                    screen, left_icon, git_branch_only, icon_bg, text_bg, icon_fg,
                    pills.left_zone.git_colors, pills,
                )
            else:
                # Nothing fits, show icon only
                _draw_pill(
                    screen, left_icon, None, icon_bg, text_bg, icon_fg, text_fg, pills
                )
        else:
            # No git, show cwd only (abbreviated)
            cwd_text = _abbreviate_path(active_info.cwd, max_text_len)
            _draw_pill(
                screen, left_icon, cwd_text, icon_bg, text_bg, icon_fg, text_fg, pills
            )

    # Position tracking - keyed by tab_id (survives reorder)
    new_tab_positions: dict[int, int] = {}

    # === Draw Center Zone (non-pinned tabs) ===
    screen.cursor.x = center_start

    for draw_idx, (orig_idx, tab_info) in enumerate(center_tabs):
        # Spacing between pills
        if draw_idx > 0:
            screen.cursor.bg = 0
            screen.draw(" " * pills.spacing)

        # Determine what to show based on strategy
        # Use visual index (1-based position in center zone) not real tab index
        visual_index = draw_idx + 1
        icon_text = _format_pill_icon(tab_info, pills, display_index=visual_index)
        show_text = strategy == "expand_all" or (
            strategy == "expand_active" and tab_info.is_active
        )
        text = _format_pill_text(tab_info, pills) if show_text else None

        # Colors - select active or inactive variant
        colors = pills.colors
        is_active = tab_info.is_active
        icon_bg = _color_int(colors.icon_bg_active if is_active else colors.icon_bg)
        text_bg = _color_int(colors.text_bg_active if is_active else colors.text_bg)
        icon_fg = _color_int(colors.icon_fg_active if is_active else colors.icon_fg)
        text_fg = _color_int(colors.text_fg_active if is_active else colors.text_fg)

        _draw_pill(screen, icon_text, text, icon_bg, text_bg, icon_fg, text_fg, pills)
        new_tab_positions[tab_info.tab.tab_id] = screen.cursor.x

    # === Draw Right Zone (pinned tabs) ===
    if right_tabs:
        right_start = screen.columns - right_width
        screen.cursor.x = right_start

        for draw_idx, (orig_idx, tab_info) in enumerate(right_tabs):
            # Spacing between pills
            if draw_idx > 0:
                screen.cursor.bg = 0
                screen.draw(" " * pills.spacing)

            # Pinned tabs: icon only (no index), always show text (expanded)
            icon_text = _format_pill_icon(tab_info, pills, display_index=None)
            text = _format_pill_text(tab_info, pills)

            # Pinned tabs always use active colors (like left zone)
            colors = pills.colors
            icon_bg = _color_int(colors.icon_bg_active)
            text_bg = _color_int(colors.text_bg_active)
            icon_fg = _color_int(colors.icon_fg_active)
            text_fg = _color_int(colors.text_fg_active)

            _draw_pill(
                screen, icon_text, text, icon_bg, text_bg, icon_fg, text_fg, pills
            )
            new_tab_positions[tab_info.tab.tab_id] = screen.cursor.x

    # Store positions for next render cycle
    _render_ctx.cached_tab_positions = new_tab_positions

    # Reset tabs for next render cycle (keep cached_tab_positions)
    _render_ctx.tabs = []
    _render_ctx.active_tab_index = 0

    return screen.cursor.x


def draw_right_status_powerline(screen: Screen, draw_data: DrawData, config) -> None:
    """Draw right-aligned status for powerline style (keyboard mode indicator)."""
    mode_cfg = config.mode_indicator

    if not mode_cfg.enabled:
        return

    mode = get_keyboard_mode()
    if not mode:
        return

    display = mode_cfg.display_names.get(mode, mode.upper())
    status_text = f" {display} "
    status_len = len(status_text)
    right_pos = screen.columns - status_len

    if right_pos <= screen.cursor.x:
        return

    gap = right_pos - screen.cursor.x
    screen.draw(" " * gap)

    screen.cursor.fg = _color_int(mode_cfg.powerline.foreground)
    if mode_cfg.powerline.background:
        screen.cursor.bg = _color_int(mode_cfg.powerline.background)
    screen.draw(status_text)


def draw_tab_powerline(
    draw_data: DrawData,
    screen: Screen,
    tab: TabBarData,
    before: int,
    max_title_length: int,
    index: int,
    is_last: bool,
    extra_data: ExtraData,
) -> int:
    """Draw a single tab using powerline style.

    Uses kitty's built-in powerline renderer with a custom title template.
    The title template is constructed from config.styles.powerline.elements.
    """
    global _render_ctx

    config = get_config()
    if _render_ctx is None or index == 1:
        _render_ctx = RenderContext(
            colors=UnifiedColorResolver(config, draw_data),
            config=config,
            screen_columns=screen.columns,
        )

    exe, cwd, remote_host = get_foreground_process(tab.tab_id)
    formatted = format_tab_title(
        exe, cwd, tab.title, index, tab.is_active, remote_host, config
    )

    custom_template = (
        "{fmt.fg.red}{bell_symbol}{activity_symbol}{fmt.fg.tab}" + formatted
    )
    new_draw_data = draw_data._replace(
        title_template=custom_template,
        active_title_template=custom_template,  # Use same template for active tabs
    )

    end = draw_tab_with_powerline(
        new_draw_data,
        screen,
        tab,
        before,
        max_title_length,
        index,
        is_last,
        extra_data,
    )

    if is_last:
        draw_right_status_powerline(screen, draw_data, config)

    return end


def draw_tab(
    draw_data: DrawData,
    screen: Screen,
    tab: TabBarData,
    before: int,
    max_title_length: int,
    index: int,
    is_last: bool,
    extra_data: ExtraData,
) -> int:
    """Draw a single tab, dispatching to the configured style."""
    try:
        style = get_active_style()

        if style == "pills":
            return draw_tab_pills(
                draw_data,
                screen,
                tab,
                before,
                max_title_length,
                index,
                is_last,
                extra_data,
            )
        else:
            return draw_tab_powerline(
                draw_data,
                screen,
                tab,
                before,
                max_title_length,
                index,
                is_last,
                extra_data,
            )
    except Exception as e:
        import sys
        import traceback

        print(f"[tab_bar] Error in draw_tab: {e}", file=sys.stderr)
        traceback.print_exc(file=sys.stderr)
        # Fallback to kitty's built-in
        return draw_tab_with_powerline(
            draw_data, screen, tab, before, max_title_length, index, is_last, extra_data
        )
