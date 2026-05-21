"""Content provider for kitty's zones tab bar style.

Loaded by kitty/tab_bar_zones.py. Provides:
  - tab_content()        : icon, text, and colors for each tab pill
  - left_zone_content()  : configured content kinds for the left zone
  - right_zone_content() : configured content kinds for the right zone
  - PILL_* constants     : pill glyph configuration (read from tabbar.toml)

Layout, positioning, and drawing live in the zones engine; this module
returns content only. All glyphs, status symbols, and specific color
picks live in tabbar.toml — Python source contains no glyph literals.
"""

import os
import subprocess
import sys
from pathlib import Path

_config_dir = Path.home() / ".config" / "kitty"
if str(_config_dir) not in sys.path:
    sys.path.insert(0, str(_config_dir))

from kitty.boss import get_boss

try:
    from kitty.fast_data_types import wcswidth as _wcswidth
except ImportError:
    _wcswidth = None
from kitty.tab_bar import DrawData, TabBarData
from kitty.tab_bar_zones import TabContent, ZoneContent

from tabbar_config import (
    UnifiedColorResolver,
    _GIT_STATUS_FIELDS,
    get_config,
    get_icon,
)


# --- Pill glyph constants (read by zones engine) ---

_config = get_config()
_bar = _config.bar

PILL_BORDER_LEFT = _bar.border_left
PILL_BORDER_RIGHT = _bar.border_right
PILL_SEPARATOR = _bar.separator
PILL_SPACING = _bar.spacing


# --- Helpers ---


def _display_width(s: str) -> int:
    if _wcswidth is not None:
        w = _wcswidth(s)
        return w if w >= 0 else len(s)
    return len(s)


_home = os.path.expanduser("~")
_SHELLS = {
    "zsh",
    "bash",
    "fish",
    "sh",
    "nu",
    "tcsh",
    "dash",
    "ksh",
    "pwsh",
    "elvish",
    "xonsh",
    "-zsh",
    "-bash",
    "-fish",
    "-sh",
}

if _config.extra_shells:
    _SHELLS.update(_config.extra_shells)


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


# --- Git status ---

_git_cache: dict[str, tuple[tuple[float, float], tuple[str, dict[str, int]]]] = {}
_GIT_CACHE_MAX = 50
_git_dir_cache: dict[str, Path | None] = {}
_GIT_DIR_CACHE_MAX = 100
_last_titles: dict[int, str] = {}
_LAST_TITLES_MAX = 50


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
            capture_output=True,
            text=True,
            timeout=0.5,
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
                    capture_output=True,
                    text=True,
                    timeout=0.3,
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
        remainder = cwd[len(_home) :]
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
    ellipsis = get_config().ellipsis
    if max_len > _display_width(ellipsis):
        return parts[-1][: max_len - _display_width(ellipsis)] + ellipsis
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
    """Return display content for a single tab pill.

    Pills are icon+index only (text=None); the active title lives in the
    right zone.
    """
    config = get_config()
    bar = config.bar

    exe, _cwd, _hostname = get_foreground_process(tab.tab_id)
    icon_str = get_icon(exe)

    icon_parts = []
    for element in bar.icon_elements:
        if element == "index" and not is_pinned:
            icon_parts.append(str(index))
        elif element == "icon":
            icon_parts.append(icon_str)
    icon = (
        " ".join(icon_parts)
        if icon_parts
        else (str(index) if not is_pinned else icon_str)
    )

    icon_bg = _color_int(
        bar.active_bg if is_active else bar.inactive_bg, draw_data
    )
    icon_fg = _color_int(
        bar.active_fg if is_active else bar.inactive_fg, draw_data
    )

    return TabContent(
        icon=icon,
        text=None,
        icon_fg=icon_fg,
        icon_bg=icon_bg,
        text_fg=0,
        text_bg=0,
    )


# --- Content kind renderers ---
#
# Each renderer returns a tuple of (text, color_int) parts, or None when
# it has nothing to contribute. The zone dispatcher owns icon resolution,
# mode-color shift, SSH override, chrome overhead, and composition.

Parts = tuple[tuple[str, int], ...]


def _render_cwd(
    zone_cfg,
    active_tab: TabBarData,
    draw_data: DrawData,
    text_budget: int,
) -> Parts | None:
    """Abbreviated working directory."""
    config = get_config()
    _exe, cwd, _hostname = get_foreground_process(active_tab.tab_id)
    if not cwd:
        return None
    cwd_text = _abbreviate_path(cwd, text_budget)
    if not cwd_text:
        return None
    return ((cwd_text, _color_int(config.git.directory, draw_data)),)


def _render_git(
    zone_cfg,
    active_tab: TabBarData,
    draw_data: DrawData,
    text_budget: int,
) -> Parts | None:
    """Git branch + status indicators. Skipped for remote sessions."""
    config = get_config()
    _exe, cwd, hostname = get_foreground_process(active_tab.tab_id)
    if hostname or not cwd:
        return None
    git_data = _get_git_status_raw(cwd)
    if not git_data:
        return None
    branch, counts = git_data
    full = _format_git_parts(branch, counts, False, config.git, draw_data)
    full_len = sum(_display_width(t) for t, _ in full)
    if full_len <= text_budget:
        return tuple(full)
    branch_only = _format_git_parts(branch, counts, True, config.git, draw_data)
    branch_len = sum(_display_width(t) for t, _ in branch_only)
    if branch_len <= text_budget:
        return tuple(branch_only)
    return None


def _render_cwd_git(
    zone_cfg,
    active_tab: TabBarData,
    draw_data: DrawData,
    text_budget: int,
) -> Parts | None:
    """Compound cwd + git renderer.

    Progressive collapse on tight budgets:
        cwd + full_git  ->  full_git only  ->  branch_only  ->  empty
    """
    config = get_config()
    _exe, cwd, hostname = get_foreground_process(active_tab.tab_id)

    git_data = None
    if cwd and not hostname:
        git_data = _get_git_status_raw(cwd)

    git_cfg = config.git

    if git_data:
        branch, counts = git_data
        full = _format_git_parts(branch, counts, False, git_cfg, draw_data)
        branch_only = _format_git_parts(branch, counts, True, git_cfg, draw_data)
        full_len = sum(_display_width(t) for t, _ in full)
        branch_len = sum(_display_width(t) for t, _ in branch_only)

        cwd_text = _abbreviate_path(cwd, text_budget - full_len - 1)
        if cwd_text and _display_width(cwd_text) + 1 + full_len <= text_budget:
            parts: list[tuple[str, int]] = [
                (cwd_text + " ", _color_int(git_cfg.directory, draw_data))
            ]
            parts.extend(full)
            return tuple(parts)
        if full_len <= text_budget:
            return tuple(full)
        if branch_len <= text_budget:
            return tuple(branch_only)
        return None

    cwd_text = _abbreviate_path(cwd, text_budget) if cwd else None
    if cwd_text:
        return ((cwd_text, _color_int(git_cfg.directory, draw_data)),)
    return None


def _truncate_title(text: str, budget: int) -> str:
    """Truncate text to fit budget cells (end-truncation only)."""
    if budget < 1:
        return ""
    ellipsis = get_config().ellipsis
    ell_w = _display_width(ellipsis)
    if budget <= ell_w:
        return text[:budget]
    return text[: budget - ell_w] + ellipsis


def _render_text(
    zone_cfg,
    text: str,
    draw_data: DrawData,
    text_budget: int,
) -> Parts | None:
    """Format a single text string as the zone's text part.

    Returns None for empty input or when text_budget is below the zone's
    min_text_budget. Truncates overflow with the configured ellipsis.
    """
    if not text or text_budget < zone_cfg.min_text_budget:
        return None
    if _display_width(text) > text_budget:
        text = _truncate_title(text, text_budget)
    return ((text, _color_int(get_config().bar.text_fg, draw_data)),)


def _render_title(
    zone_cfg,
    active_tab: TabBarData,
    draw_data: DrawData,
    text_budget: int,
) -> Parts | None:
    """Active tab title with sticky-cache fallback.

    Resolution order: override_title -> program_title -> shell_title ->
    sticky cache (if config.sticky_last_cmd is true).
    """
    config = get_config()

    current_cmd_title = active_tab.program_title or active_tab.shell_title
    if current_cmd_title:
        if len(_last_titles) >= _LAST_TITLES_MAX:
            _last_titles.clear()
        _last_titles[active_tab.tab_id] = current_cmd_title

    title = (
        active_tab.override_title
        or active_tab.program_title
        or active_tab.shell_title
    )
    if not title and config.sticky_last_cmd:
        title = _last_titles.get(active_tab.tab_id, "")

    return _render_text(zone_cfg, title or "", draw_data, text_budget)


def _render_tab_label(
    zone_cfg,
    active_tab: TabBarData,
    draw_data: DrawData,
    text_budget: int,
) -> Parts | None:
    """User-set tab name (`Tab.name`, set by set_tab_title)."""
    return _render_text(
        zone_cfg, active_tab.tab_name or "", draw_data, text_budget
    )


_RENDERERS = {
    "cwd": _render_cwd,
    "git": _render_git,
    "cwd_git": _render_cwd_git,
    "title": _render_title,
    "tab_label": _render_tab_label,
}


def _dispatch_zone_content(
    zone_cfg,
    active_tab: TabBarData,
    draw_data: DrawData,
    max_width: int,
) -> ZoneContent | None:
    """Render zone content from configured kinds.

    Resolves zone-level chrome once (icon with SSH/mode override, icon
    colors, text background), then walks `zone_cfg.content` in order,
    allocating remaining text budget per kind. Renderers return parts
    only; this function composes them with `config.content_separator`.

    Always-visible empty pill: when the zone is configured but every
    renderer returns None, emit a zero-width text segment so the engine
    still draws the pill chrome.
    """
    if not zone_cfg.content:
        return None

    config = get_config()
    bar = config.bar
    mode_cfg = config.mode_indicator
    mode = get_keyboard_mode()

    _exe, _cwd, hostname = get_foreground_process(active_tab.tab_id)

    mode_active = bool(mode) and mode_cfg.enabled

    if mode_active and zone_cfg.show_mode_indicator:
        icon = mode_cfg.display_names.get(mode, mode.upper())
    elif hostname and zone_cfg.ssh_icon:
        icon = zone_cfg.ssh_icon
    else:
        icon = zone_cfg.icon

    if mode_active:
        icon_bg = _color_int(mode_cfg.bg or bar.active_bg, draw_data)
        icon_fg = _color_int(mode_cfg.fg or bar.active_fg, draw_data)
    else:
        icon_bg = _color_int(bar.active_bg, draw_data)
        icon_fg = _color_int(bar.active_fg, draw_data)

    text_bg = _color_int(bar.text_bg, draw_data)
    text_fg = _color_int(bar.text_fg, draw_data)

    # Fixed zone overhead: BL + icon-pad + SEP + text-pad + BR = 5 cells (plus icon width).
    overhead = _display_width(icon) + 5
    text_budget = max_width - overhead
    if text_budget < zone_cfg.min_text_budget:
        return None

    sep = config.content_separator
    sep_width = _display_width(sep)

    merged_parts: list[tuple[str, int]] = []
    used_width = 0

    for kind in zone_cfg.content:
        renderer = _RENDERERS.get(kind)
        if renderer is None:
            continue
        remaining = text_budget - used_width
        if merged_parts:
            remaining -= sep_width
        if remaining <= 0:
            break
        kind_parts = renderer(zone_cfg, active_tab, draw_data, remaining)
        if not kind_parts:
            continue
        kind_width = sum(_display_width(t) for t, _ in kind_parts)
        if kind_width == 0:
            continue
        if merged_parts:
            sep_color = merged_parts[-1][1]
            merged_parts.append((sep, sep_color))
            used_width += sep_width
        merged_parts.extend(kind_parts)
        used_width += kind_width

    if not merged_parts:
        merged_parts = [("", text_fg)]

    return ZoneContent(
        icon=icon,
        parts=tuple(merged_parts),
        icon_fg=icon_fg,
        icon_bg=icon_bg,
        text_bg=text_bg,
    )


def left_zone_content(
    active_tab: TabBarData,
    draw_data: DrawData,
    max_width: int,
) -> ZoneContent | None:
    """Render left zone content."""
    return _dispatch_zone_content(
        get_config().left_zone, active_tab, draw_data, max_width
    )


def right_zone_content(
    active_tab: TabBarData,
    draw_data: DrawData,
    max_width: int,
) -> ZoneContent | None:
    """Render right zone content."""
    return _dispatch_zone_content(
        get_config().right_zone, active_tab, draw_data, max_width
    )


def _format_git_parts(
    branch: str,
    counts: dict[str, int],
    branch_only: bool,
    git_cfg,
    draw_data: DrawData,
) -> list[tuple[str, int]]:
    """Format git info into (text, color_int) pairs.

    Glyphs come from git_cfg.symbols; colors from git_cfg.<field>.
    """
    parts: list[tuple[str, int]] = []
    syms = git_cfg.symbols

    if syms.branch_icon:
        parts.append(
            (syms.branch_icon + " ", _color_int(git_cfg.branch_icon, draw_data))
        )
    parts.append((branch, _color_int(git_cfg.branch, draw_data)))

    if branch_only:
        return parts

    status_parts: list[tuple[str, int]] = []
    for key in _GIT_STATUS_FIELDS:
        if counts.get(key, 0) <= 0:
            continue
        sym = getattr(syms, key, "")
        if not sym:
            continue
        color_name = getattr(git_cfg, key, "foreground")
        status_parts.append((f"{sym}{counts[key]}", _color_int(color_name, draw_data)))

    if status_parts:
        sep_color = _color_int(git_cfg.branch, draw_data)
        parts.append((" ", sep_color))
        for i, (text, color) in enumerate(status_parts):
            if i > 0:
                parts.append((" ", sep_color))
            parts.append((text, color))

    return parts
