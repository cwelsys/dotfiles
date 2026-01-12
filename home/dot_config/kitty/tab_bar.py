import os
from functools import lru_cache

from kitty.boss import get_boss
from kitty.fast_data_types import Screen, add_timer
from kitty.tab_bar import (
    DrawData,
    ExtraData,
    TabBarData,
    draw_tab_with_powerline,
)

# "index", "icon", "name", "path"
DISPLAY_ELEMENTS = ["index", "icon", "path"]
RAINBOW_PATH = True
MAX_PATH_SEGMENTS = 2
PAD_START = ""
PAD_END = ""
ELEMENT_SEP = " "

PALETTE = {
    "rosewater": "f5e0dc",
    "flamingo": "f2cdcd",
    "pink": "f5c2e7",
    "mauve": "cba6f7",
    "red": "f38ba8",
    "maroon": "eba0ac",
    "peach": "fab387",
    "yellow": "f9e2af",
    "green": "a6e3a1",
    "teal": "94e2d5",
    "sky": "89dceb",
    "sapphire": "74c7ec",
    "blue": "89b4fa",
    "lavender": "b4befe",
    "text": "cdd6f4",
    "subtext1": "bac2de",
    "subtext0": "a6adc8",
    "overlay2": "9399b2",
    "overlay1": "7f849c",
    "overlay0": "6c7086",
    "surface2": "585b70",
    "surface1": "45475a",
    "surface0": "313244",
    "base": "1e1e2e",
    "mantle": "181825",
    "crust": "11111b",
}

ACTIVE_PATH_MAIN = "crust"  # current directory
ACTIVE_PATH_MUTED = "crust"  # preceding directories
ICON_COLOR_ACTIVE = "mantle"
ICON_COLOR_INACTIVE = "blue"
RAINBOW_COLORS = ["red", "peach", "yellow", "green", "teal", "blue", "lavender"]
MODE_INDICATOR_COLOR = "mauve"
MODE_INDICATOR_BG = "surface0"
SHOW_MODE_INDICATOR = True

# defaults to MODE_NAME
MODE_DISPLAY_NAMES = {
    "leader": "󰌌",
}


def _c(name: str) -> str:
    """Resolve color name to hex value."""
    return PALETTE.get(name, name)


_REFRESH_FLAG = "/tmp/kitty_tab_refresh"
_REFRESH_DELAY = 0.15

_last_refresh_mtime: float = 0
_pending_timer = None


def _do_refresh(timer_id) -> None:
    global _pending_timer
    _pending_timer = None
    tm = get_boss().active_tab_manager
    if tm is not None:
        tm.mark_tab_bar_dirty()


def _check_refresh_request() -> None:
    global _last_refresh_mtime, _pending_timer
    try:
        mtime = os.path.getmtime(_REFRESH_FLAG)
        if mtime > _last_refresh_mtime:
            _last_refresh_mtime = mtime
            if _pending_timer is None:
                _pending_timer = add_timer(_do_refresh, _REFRESH_DELAY, False)
    except FileNotFoundError:
        pass


_ICONS_CACHE: dict[str, str] | None = None
_CONFIG_CACHE: dict[str, str] | None = None


def _load_from_yaml() -> tuple[dict[str, str], dict[str, str]]:
    from pathlib import Path

    icons = {}
    config = {}
    config_path = Path.home() / ".config/kitty/icons.yml"

    if not config_path.exists():
        return icons, config

    try:
        with open(config_path, "r", encoding="utf-8") as f:
            current_section = None
            for line in f:
                stripped = line.strip()
                if stripped == "icons:":
                    current_section = "icons"
                    continue
                elif stripped == "config:":
                    current_section = "config"
                    continue
                elif stripped and not line.startswith(" ") and ":" in stripped:
                    current_section = None
                    continue

                if current_section and ":" in stripped:
                    parts = stripped.split(":", 1)
                    if len(parts) == 2:
                        key = parts[0].strip().strip("\"'")
                        value = parts[1].strip().strip("\"'")
                        if key and value:
                            if current_section == "icons":
                                icons[key] = value
                            elif current_section == "config":
                                config[key] = value
    except Exception:
        pass

    return icons, config


def _ensure_loaded():
    global _ICONS_CACHE, _CONFIG_CACHE
    if _ICONS_CACHE is None:
        _ICONS_CACHE, _CONFIG_CACHE = _load_from_yaml()


def _get_icons() -> dict[str, str]:
    _ensure_loaded()
    return _ICONS_CACHE or {}


def _get_fallback_icon() -> str:
    _ensure_loaded()
    return (_CONFIG_CACHE or {}).get("fallback-icon", "")


def get_icon(exe_name: str) -> str:
    icons = _get_icons()
    return icons.get(exe_name, _get_fallback_icon())


_home = os.path.expanduser("~")


@lru_cache(maxsize=64)
def get_path_parts(cwd: str) -> tuple[str, ...]:
    """Get path as tuple of parts, shortened for display."""
    if cwd.startswith(_home):
        cwd = "~" + cwd[len(_home) :]

    parts = cwd.strip("/").split("/")
    if len(parts) > MAX_PATH_SEGMENTS:
        parts = [".."] + parts[-MAX_PATH_SEGMENTS:]

    return tuple(parts)


@lru_cache(maxsize=128)
def colorize_parts(
    parts: tuple[str, ...], sep: str, tab_index: int, is_active: bool
) -> str:
    """Colorize segments with rainbow colors."""
    colored_parts = []
    num_parts = len(parts)

    for i, part in enumerate(parts):
        is_last = i == num_parts - 1

        if is_active:
            color = _c(ACTIVE_PATH_MAIN) if is_last else _c(ACTIVE_PATH_MUTED)
        else:
            color_idx = (tab_index + i) % len(RAINBOW_COLORS)
            color = _c(RAINBOW_COLORS[color_idx])

        colored_parts.append(f"{{fmt.fg._{color}}}{part}")

    colored_sep = f"{{fmt.fg.tab}}{sep}"
    return colored_sep.join(colored_parts) + "{fmt.fg.tab}"


# Separators to try for rainbow coloring, first match wins
TITLE_SEPARATORS = ["/", " - ", ": ", " | "]


def colorize_title(text: str, tab_index: int, is_active: bool) -> str:
    """Colorize any title by splitting on common separators."""
    if not RAINBOW_PATH:
        return text

    for sep in TITLE_SEPARATORS:
        if sep in text:
            parts = tuple(text.split(sep))
            return colorize_parts(parts, sep, tab_index, is_active)

    if is_active:
        color = _c(ACTIVE_PATH_MAIN)
    else:
        color_idx = tab_index % len(RAINBOW_COLORS)
        color = _c(RAINBOW_COLORS[color_idx])
    return f"{{fmt.fg._{color}}}{text}{{fmt.fg.tab}}"


def format_path(cwd: str, index: int, is_active: bool) -> str:
    """Format path, optionally with rainbow colors."""
    parts = get_path_parts(cwd)
    if RAINBOW_PATH:
        return colorize_parts(parts, "/", index, is_active)
    return "/".join(parts)


def get_foreground_process(tab_id: int) -> tuple[str, str]:
    """Get the foreground process name and cwd for a tab."""
    boss = get_boss()
    tab = boss.tab_for_id(tab_id)
    if not tab:
        return ("zsh", "")

    window = tab.active_window
    if not window:
        return ("zsh", "")

    exe = "zsh"
    cwd = ""

    try:
        procs = window.child.foreground_processes
        if procs:
            procs = sorted(procs, key=lambda p: p.get("pid", 0))
            cwd = procs[0].get("cwd", "")

            shells = {"zsh", "bash", "fish", "sh", "nu", "tcsh", "-zsh", "-bash"}
            for proc in procs:
                cmdline = proc.get("cmdline", [])
                if cmdline:
                    proc_exe = os.path.basename(cmdline[0])
                    if proc_exe not in shells:
                        exe = proc_exe
                        break
            else:
                cmdline = procs[0].get("cmdline", [])
                if cmdline:
                    exe = os.path.basename(cmdline[0])
                    if exe.startswith("-"):
                        exe = exe[1:]
    except Exception:
        pass

    if not cwd:
        from kitty.tab_bar import TabAccessor

        ta = TabAccessor(tab_id)
        cwd = ta.active_wd or ""

    return (exe, cwd)


def format_tab_title(
    exe: str, cwd: str, title: str, index: int, is_active: bool
) -> str:
    """Format tab title based on DISPLAY_ELEMENTS."""
    parts = []
    icon_color = _c(ICON_COLOR_ACTIVE) if is_active else _c(ICON_COLOR_INACTIVE)

    for element in DISPLAY_ELEMENTS:
        if element == "index":
            parts.append(str(index))
        elif element == "icon":
            icon = get_icon(exe)
            parts.append(f"{{fmt.fg._{icon_color}}}{icon}{{fmt.fg.tab}}")
        elif element == "name":
            parts.append(exe)
        elif element == "path":
            display = title or cwd
            if display:
                if display.startswith(("~", "/", ".", "…")):
                    parts.append(format_path(display, index, is_active))
                else:
                    parts.append(colorize_title(display, index, is_active))

    content = ELEMENT_SEP.join(parts)
    return f"{PAD_START}{content}{PAD_END}"


def get_keyboard_mode() -> str:
    """Get the current keyboard mode name, empty string if normal."""
    try:
        mode = get_boss().mappings.current_keyboard_mode_name
        return mode if mode else ""
    except Exception:
        return ""


def draw_right_status(screen: Screen, draw_data: DrawData) -> None:
    """Draw right-aligned status (keyboard mode indicator, etc.)."""
    if not SHOW_MODE_INDICATOR:
        return

    mode = get_keyboard_mode()
    if not mode:
        return

    display = MODE_DISPLAY_NAMES.get(mode, mode.upper())
    status_text = f" {display} "
    status_len = len(status_text)
    right_pos = screen.columns - status_len

    if right_pos <= screen.cursor.x:
        return

    gap = right_pos - screen.cursor.x
    screen.draw(" " * gap)

    fg = _c(MODE_INDICATOR_COLOR)
    bg = _c(MODE_INDICATOR_BG)
    screen.cursor.fg = int(fg, 16)
    screen.cursor.bg = int(bg, 16)
    screen.draw(status_text)


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
    """Draw a single tab with foreground process info and nerd font icon."""
    _check_refresh_request()

    exe, cwd = get_foreground_process(tab.tab_id)
    formatted = format_tab_title(exe, cwd, tab.title, index, tab.is_active)

    new_draw_data = draw_data._replace(
        title_template="{fmt.fg.red}{bell_symbol}{activity_symbol}{fmt.fg.tab}"
        + formatted
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
        draw_right_status(screen, draw_data)

    return end
