"""Content provider for kitty's zones tab bar style.

This module is loaded by kitty/tab_bar_zones.py. It provides:
  - tab_content()        — icon, text, and colors for each tab pill
  - left_zone_content()  — cwd/git/mode content for the left zone
  - PILL_* constants     — pill glyph configuration

All layout, positioning, and drawing are handled by the zones engine.
This module only provides content.

Configuration is loaded from ~/.config/kitty/tabbar.toml via tabbar_config.py.
"""

import os
import subprocess
import sys
from pathlib import Path

_config_dir = Path.home() / ".config" / "kitty"
if str(_config_dir) not in sys.path:
    sys.path.insert(0, str(_config_dir))

from kitty.boss import get_boss
from kitty.fast_data_types import Screen
try:
    from kitty.fast_data_types import wcswidth as _wcswidth
except ImportError:
    _wcswidth = None
from kitty.tab_bar import DrawData, TabBarData, as_rgb
from kitty.tab_bar_zones import TabContent, ZoneContent

from tabbar_config import (
    UnifiedColorResolver,
    get_config,
    get_icon,
)


# --- Pill glyph constants (read by zones engine) ---

_config = get_config()
_pills = _config.styles.pills

PILL_BORDER_LEFT = _pills.border_left
PILL_BORDER_RIGHT = _pills.border_right
PILL_SEPARATOR = _pills.separator
PILL_SPACING = _pills.spacing


# --- Helpers ---

def _display_width(s: str) -> int:
    if _wcswidth is not None:
        w = _wcswidth(s)
        return w if w >= 0 else len(s)
    return len(s)


_home = os.path.expanduser("~")
_SHELLS = {
    "zsh", "bash", "fish", "sh", "nu", "tcsh", "dash", "ksh", "pwsh",
    "elvish", "xonsh",
    "-zsh", "-bash", "-fish", "-sh",
}

# Apply configurable extra shells
_cfg = get_config()
if _cfg.general.extra_shells:
    _SHELLS.update(_cfg.general.extra_shells)


# --- Process detection ---

def get_foreground_process(tab_id: int) -> tuple[str, str, str | None]:
    """Get (exe, cwd, remote_host) for tab's foreground process."""
    try:
        from kitty.tab_bar import TabAccessor
        ta = TabAccessor(tab_id)
        exe = ta.active_exe or "zsh"
        cwd = ta.active_wd or ""

        remote_host = None
        try:
            boss = get_boss()
            tab = boss.tab_for_id(tab_id)
            if tab and tab.active_window:
                user_vars = tab.active_window.user_vars
                proc = user_vars.get("PROC")
                if proc and proc not in _SHELLS:
                    exe = proc
                remote_cwd = user_vars.get("REMOTE_CWD")
                if remote_cwd:
                    cwd = remote_cwd
                remote_host = user_vars.get("REMOTE_HOST") or None
        except Exception:
            pass

        return (exe, cwd, remote_host)
    except Exception:
        return ("zsh", "", None)


# Process info cache: tab_id -> (cache_key, (exe, cwd, hostname))
_proc_cache: dict[int, tuple[str, tuple[str, str, str | None]]] = {}


def _get_process_cached(tab: TabBarData) -> tuple[str, str, str | None]:
    """Get foreground process with caching across render cycles."""
    cache_key = f"{tab.title}:{tab.is_active}:{tab.num_windows}"
    if tab.tab_id in _proc_cache:
        old_key, old_data = _proc_cache[tab.tab_id]
        if old_key == cache_key:
            return old_data
    data = get_foreground_process(tab.tab_id)
    _proc_cache[tab.tab_id] = (cache_key, data)
    return data


# --- Git status ---

_git_cache: dict[str, tuple[tuple[float, float], tuple[str, dict[str, int]]]] = {}
_GIT_CACHE_MAX = 50
_git_dir_cache: dict[str, Path | None] = {}
_GIT_DIR_CACHE_MAX = 100


def _find_git_dir(cwd: str) -> Path | None:
    if cwd in _git_dir_cache:
        return _git_dir_cache[cwd]
    if len(_git_dir_cache) >= _GIT_DIR_CACHE_MAX:
        _git_dir_cache.clear()
    try:
        path = Path(cwd)
        for parent in [path, *path.parents]:
            git_path = parent / ".git"
            if git_path.is_dir():
                _git_dir_cache[cwd] = git_path
                return git_path
            if git_path.is_file():
                content = git_path.read_text().strip()
                if content.startswith("gitdir:"):
                    result = Path(content[7:].strip())
                    _git_dir_cache[cwd] = result
                    return result
        _git_dir_cache[cwd] = None
        return None
    except Exception:
        _git_dir_cache[cwd] = None
        return None


def _parse_git_output(raw: str) -> tuple[str, dict[str, int]]:
    branch = ""
    counts = {
        "ahead": 0, "behind": 0, "staged": 0, "modified": 0,
        "deleted": 0, "renamed": 0, "untracked": 0, "conflicted": 0,
    }
    for line in raw.splitlines():
        if line.startswith("# branch.head "):
            branch = line.split()[-1]
        elif line.startswith("# branch.ab "):
            parts = line.split()
            if len(parts) >= 4:
                counts["ahead"] = int(parts[2].lstrip("+"))
                counts["behind"] = abs(int(parts[3]))
        elif line.startswith("2 "):
            counts["renamed"] += 1
        elif line.startswith("1 "):
            parts = line.split()
            if len(parts) >= 2:
                xy = parts[1]
                if len(xy) >= 2:
                    if xy[0] == "D":
                        counts["deleted"] += 1
                    elif xy[0] not in (".", "?"):
                        counts["staged"] += 1
                    if xy[1] == "D":
                        counts["deleted"] += 1
                    elif xy[1] not in (".", "?"):
                        counts["modified"] += 1
        elif line.startswith("u "):
            counts["conflicted"] += 1
        elif line.startswith("? "):
            counts["untracked"] += 1
    return branch, counts


_GIT_BRANCH_ICON = "\ue725"


def _get_git_status_raw(cwd: str) -> tuple[str, dict[str, int]] | None:
    git_dir = _find_git_dir(cwd)
    if not git_dir:
        return None

    index = git_dir / "index"
    try:
        current_mtime = index.stat().st_mtime if index.exists() else 0
    except Exception:
        current_mtime = 0

    stash_ref = git_dir / "refs" / "stash"
    try:
        stash_mtime = stash_ref.stat().st_mtime if stash_ref.exists() else 0
    except Exception:
        stash_mtime = 0

    combined_mtime = (current_mtime, stash_mtime)
    repo_key = str(git_dir.parent) if git_dir.name == ".git" else str(git_dir)

    if repo_key in _git_cache:
        cached_mtime, cached_data = _git_cache[repo_key]
        if cached_mtime == combined_mtime:
            return cached_data

    try:
        result = subprocess.run(
            ["git", "-C", cwd, "status", "--porcelain=v2", "--branch"],
            capture_output=True, text=True, timeout=0.5,
        )
        if result.returncode != 0:
            return None

        branch, counts = _parse_git_output(result.stdout)
        if not branch:
            return None

        if stash_ref.exists():
            try:
                stash_result = subprocess.run(
                    ["git", "-C", cwd, "stash", "list"],
                    capture_output=True, text=True, timeout=0.3,
                )
                if stash_result.returncode == 0:
                    stash_lines = stash_result.stdout.strip().splitlines()
                    counts["stashed"] = len(stash_lines)
            except Exception:
                pass

        if len(_git_cache) >= _GIT_CACHE_MAX:
            _git_cache.clear()
        _git_cache[repo_key] = (combined_mtime, (branch, counts))
        return (branch, counts)
    except Exception:
        return None


def _abbreviate_path(cwd: str, max_len: int) -> str | None:
    if not cwd:
        return None
    if len(cwd) > 1 and cwd.endswith("/"):
        cwd = cwd.rstrip("/")
    if cwd.startswith(_home):
        remainder = cwd[len(_home):]
        if remainder == "" or remainder.startswith("/"):
            cwd = "~" + remainder
    if _display_width(cwd) <= max_len:
        return cwd
    parts = cwd.split("/")
    if len(parts) <= 1:
        return cwd if _display_width(cwd) <= max_len else None
    abbreviated = []
    for part in parts[:-1]:
        if part in ("~", ""):
            abbreviated.append(part)
        elif part.startswith("."):
            abbreviated.append(part[:3] if len(part) > 3 else part)
        else:
            abbreviated.append(part[:2] if len(part) > 2 else part)
    abbreviated.append(parts[-1])
    result = "/".join(abbreviated)
    if _display_width(result) <= max_len:
        return result
    if _display_width(parts[-1]) <= max_len:
        return parts[-1]
    if max_len > 3:
        return parts[-1][:max_len - 1] + "\u2026"
    return None


def get_keyboard_mode() -> str:
    try:
        mode = get_boss().mappings.current_keyboard_mode_name
        return mode if mode else ""
    except Exception:
        return ""


# --- Color resolution (per render cycle) ---

_resolver: UnifiedColorResolver | None = None
_resolver_draw_data_id: int = 0


def _get_resolver(draw_data: DrawData) -> UnifiedColorResolver:
    """Get or refresh color resolver for current render cycle."""
    global _resolver, _resolver_draw_data_id
    dd_id = id(draw_data)
    if _resolver is None or _resolver_draw_data_id != dd_id:
        _resolver = UnifiedColorResolver(get_config(), draw_data)
        _resolver_draw_data_id = dd_id
    return _resolver


def _color_int(name: str, draw_data: DrawData) -> int:
    return _get_resolver(draw_data).resolve_to_int(name)


# --- Content provider interface ---

def tab_content(
    tab: TabBarData,
    index: int,
    is_active: bool,
    is_pinned: bool,
    draw_data: DrawData,
) -> TabContent:
    """Return display content for a single tab pill."""
    config = get_config()
    pills = config.styles.pills
    colors = pills.colors

    exe, cwd, hostname = _get_process_cached(tab)
    icon_str = get_icon(exe)

    # Build icon section
    icon_parts = []
    for element in pills.icon_elements:
        if element == "index" and not is_pinned:
            icon_parts.append(str(index))
        elif element == "icon":
            icon_parts.append(icon_str)
    icon = " ".join(icon_parts) if icon_parts else (str(index) if not is_pinned else icon_str)

    # Build text section
    text_parts = []
    for element in pills.text_elements:
        if element == "name":
            text_parts.append(exe)
        elif element == "title" and tab.title:
            text_parts.append(tab.title)
        elif element == "hostname" and hostname:
            text_parts.append(hostname)
    # Collapse to icon-only when idle (shell name is the only text)
    if text_parts == [exe] and exe in _SHELLS:
        text = None
    else:
        text = " ".join(text_parts) if text_parts else None

    # Colors
    icon_bg = _color_int(colors.icon_bg_active if is_active else colors.icon_bg, draw_data)
    icon_fg = _color_int(colors.icon_fg_active if is_active else colors.icon_fg, draw_data)
    text_bg = _color_int(colors.text_bg_active if is_active else colors.text_bg, draw_data)
    text_fg = _color_int(colors.text_fg_active if is_active else colors.text_fg, draw_data)

    return TabContent(
        icon=icon,
        text=text,
        icon_fg=icon_fg,
        icon_bg=icon_bg,
        text_fg=text_fg,
        text_bg=text_bg,
    )


def left_zone_content(
    active_tab: TabBarData,
    draw_data: DrawData,
    max_width: int,
) -> ZoneContent | None:
    """Return display content for the left zone."""
    config = get_config()
    pills = config.styles.pills

    if not pills.left_zone.enabled:
        return None

    exe, cwd, hostname = _get_process_cached(active_tab)
    mode_cfg = config.mode_indicator
    mode = get_keyboard_mode()

    # Select icon and icon colors
    if mode and mode_cfg.enabled:
        left_icon = mode_cfg.display_names.get(mode, mode.upper())
        icon_bg = _color_int(mode_cfg.pills.icon_bg, draw_data)
        icon_fg = (
            _color_int(mode_cfg.pills.icon_fg, draw_data)
            if mode_cfg.pills.icon_fg
            else _color_int(pills.colors.icon_fg_active, draw_data)
        )
    elif hostname:
        left_icon = pills.left_zone.ssh_icon
        icon_bg = _color_int(pills.colors.icon_bg_active, draw_data)
        icon_fg = _color_int(pills.colors.icon_fg_active, draw_data)
    else:
        left_icon = pills.left_zone.icon
        icon_bg = _color_int(pills.colors.icon_bg_active, draw_data)
        icon_fg = _color_int(pills.colors.icon_fg_active, draw_data)

    text_bg = _color_int(pills.colors.text_bg_active, draw_data)

    # Estimate icon section width to compute max text space
    max_text_len = max_width - _display_width(left_icon) - 6

    if max_text_len <= 0:
        return ZoneContent(
            icon=left_icon, parts=(), icon_fg=icon_fg, icon_bg=icon_bg, text_bg=text_bg,
        )

    # Git status
    git_data = None
    if pills.left_zone.use_git and cwd:
        git_data = _get_git_status_raw(cwd)

    git_colors = pills.left_zone.git_colors

    if git_data:
        branch, counts = git_data

        # Format git parts
        git_full = _format_git_parts(branch, counts, False, git_colors, draw_data)
        git_branch_only = _format_git_parts(branch, counts, True, git_colors, draw_data)
        git_full_len = sum(_display_width(t) for t, _ in git_full)
        git_branch_len = sum(_display_width(t) for t, _ in git_branch_only)

        # Progressive collapse: cwd + full git -> git only -> branch only -> icon only
        cwd_text = _abbreviate_path(cwd, max_text_len - git_full_len - 1)
        if cwd_text and _display_width(cwd_text) + 1 + git_full_len <= max_text_len:
            parts = [(cwd_text + " ", _color_int(git_colors.directory, draw_data))]
            parts.extend(git_full)
            return ZoneContent(
                icon=left_icon, parts=tuple(parts),
                icon_fg=icon_fg, icon_bg=icon_bg, text_bg=text_bg,
            )
        if git_full_len <= max_text_len:
            return ZoneContent(
                icon=left_icon, parts=tuple(git_full),
                icon_fg=icon_fg, icon_bg=icon_bg, text_bg=text_bg,
            )
        if git_branch_len <= max_text_len:
            return ZoneContent(
                icon=left_icon, parts=tuple(git_branch_only),
                icon_fg=icon_fg, icon_bg=icon_bg, text_bg=text_bg,
            )
        return ZoneContent(
            icon=left_icon, parts=(), icon_fg=icon_fg, icon_bg=icon_bg, text_bg=text_bg,
        )

    # No git — show cwd
    cwd_text = _abbreviate_path(cwd, max_text_len)
    if cwd_text:
        text_fg = _color_int(pills.colors.text_fg_active, draw_data)
        return ZoneContent(
            icon=left_icon, parts=((cwd_text, text_fg),),
            icon_fg=icon_fg, icon_bg=icon_bg, text_bg=text_bg,
        )

    return ZoneContent(
        icon=left_icon, parts=(), icon_fg=icon_fg, icon_bg=icon_bg, text_bg=text_bg,
    )


def _format_git_parts(
    branch: str,
    counts: dict[str, int],
    branch_only: bool,
    git_colors,
    draw_data: DrawData,
) -> list[tuple[str, int]]:
    """Format git info into (text, color_int) pairs."""
    parts: list[tuple[str, int]] = []

    parts.append((_GIT_BRANCH_ICON + " ", _color_int(git_colors.git_branch_icon, draw_data)))
    parts.append((branch, _color_int(git_colors.git_branch, draw_data)))

    if branch_only:
        return parts

    symbols = [
        ("stashed", "*"), ("deleted", "\u2718"), ("staged", "+"),
        ("modified", "!"), ("renamed", "\u00bb"), ("untracked", "?"),
        ("conflicted", "~"), ("ahead", "\u21e1"), ("behind", "\u21e3"),
    ]
    status_parts = []
    for key, sym in symbols:
        if counts.get(key, 0) > 0:
            color_name = getattr(git_colors, f"git_{key}", "foreground")
            status_parts.append((f"{sym}{counts[key]}", _color_int(color_name, draw_data)))

    if status_parts:
        parts.append((" ", _color_int(git_colors.git_branch, draw_data)))
        for i, (text, color) in enumerate(status_parts):
            if i > 0:
                parts.append((" ", _color_int(git_colors.git_branch, draw_data)))
            parts.append((text, color))

    return parts


# --- Powerline style (kept for tab_bar_style=custom fallback) ---

from kitty.tab_bar import (
    ExtraData,
    draw_tab_with_powerline,
)


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
    """draw_tab entry point — only used when tab_bar_style=custom (powerline mode).

    When tab_bar_style=zones, kitty calls the zones engine directly and this
    function is never invoked.
    """
    config = get_config()
    style = config.general.style

    if style == "powerline":
        return _draw_tab_powerline(
            draw_data, screen, tab, before, max_title_length, index, is_last, extra_data
        )
    # If someone sets tab_bar_style=custom with pills style, fall through to powerline
    return draw_tab_with_powerline(
        draw_data, screen, tab, before, max_title_length, index, is_last, extra_data
    )


def _draw_tab_powerline(
    draw_data: DrawData,
    screen: Screen,
    tab: TabBarData,
    before: int,
    max_title_length: int,
    index: int,
    is_last: bool,
    extra_data: ExtraData,
) -> int:
    """Powerline style with custom title formatting."""
    config = get_config()
    powerline = config.styles.powerline

    exe, cwd, remote_host = get_foreground_process(tab.tab_id)

    parts = []
    resolver = _get_resolver(draw_data)
    colors_cfg = powerline.colors

    if tab.is_active:
        icon_color = resolver.resolve_to_hex(colors_cfg.icon_active)
    elif powerline.rainbow_index_icon:
        icon_color = resolver.resolve_to_hex(
            colors_cfg.rainbow[(index - 1) % len(colors_cfg.rainbow)]
        )
    else:
        icon_color = resolver.resolve_to_hex(colors_cfg.icon_inactive)

    for element in powerline.elements:
        if element == "index":
            parts.append(f"{{fmt.fg._{icon_color}}}{index}{{fmt.fg.tab}}")
        elif element == "icon":
            icon = get_icon(exe)
            parts.append(f"{{fmt.fg._{icon_color}}}{icon}{{fmt.fg.tab}}")
        elif element == "name":
            parts.append(exe)
        elif element == "path":
            display = tab.title or cwd
            if display:
                parts.append(display)
        elif element == "ssh" and remote_host:
            parts.append(f"{{fmt.fg._{icon_color}}}{powerline.ssh_icon}{{fmt.fg.tab}}")
        elif element == "hostname" and remote_host:
            parts.append(f"{{fmt.fg._{icon_color}}}{remote_host}{{fmt.fg.tab}}")

    content = powerline.element_sep.join(parts)
    formatted = f"{powerline.pad_start}{content}{powerline.pad_end}"

    custom_template = (
        "{fmt.fg.red}{bell_symbol}{activity_symbol}{fmt.fg.tab}" + formatted
    )
    new_draw_data = draw_data._replace(
        title_template=custom_template,
        active_title_template=custom_template,
    )

    end = draw_tab_with_powerline(
        new_draw_data, screen, tab, before, max_title_length, index, is_last, extra_data
    )

    # Right-aligned mode indicator on last tab
    if is_last:
        mode_cfg = config.mode_indicator
        if mode_cfg.enabled:
            mode = get_keyboard_mode()
            if mode:
                display = mode_cfg.display_names.get(mode, mode.upper())
                status_text = f" {display} "
                status_len = len(status_text)
                right_pos = screen.columns - status_len
                if right_pos > screen.cursor.x:
                    screen.draw(" " * (right_pos - screen.cursor.x))
                    screen.cursor.fg = _color_int(mode_cfg.powerline.foreground, draw_data)
                    if mode_cfg.powerline.background:
                        screen.cursor.bg = _color_int(mode_cfg.powerline.background, draw_data)
                    screen.draw(status_text)

    return end
