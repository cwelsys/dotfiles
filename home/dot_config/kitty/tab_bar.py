import os
from kitty.boss import get_boss
from kitty.fast_data_types import Screen, add_timer
from kitty.tab_bar import (
    DrawData,
    ExtraData,
    TabBarData,
    draw_tab_with_powerline,
)


_REFRESH_FLAG = "/tmp/kitty_tab_refresh"
_REFRESH_DELAY = 0.15

_last_refresh_mtime: float = 0
_pending_timer = None


def _do_refresh(timer_id) -> None:
    """Trigger tab bar redraw after delay."""
    global _pending_timer
    _pending_timer = None
    tm = get_boss().active_tab_manager
    if tm is not None:
        tm.mark_tab_bar_dirty()


def _check_refresh_request() -> None:
    """Check if a refresh was requested via file touch, schedule timer if so."""
    global _last_refresh_mtime, _pending_timer
    try:
        mtime = os.path.getmtime(_REFRESH_FLAG)
        if mtime > _last_refresh_mtime:
            _last_refresh_mtime = mtime
            if _pending_timer is None:
                _pending_timer = add_timer(_do_refresh, _REFRESH_DELAY, False)
    except FileNotFoundError:
        pass


#   name, path, icon
DISPLAY_FORMAT = "icon+path"
MAX_PATH_SEGMENTS = 3
COLORS = {
    "rosewater": "#f5e0dc",
    "flamingo": "#f2cdcd",
    "pink": "#f5c2e7",
    "mauve": "#cba6f7",
    "red": "#f38ba8",
    "maroon": "#eba0ac",
    "peach": "#fab387",
    "yellow": "#f9e2af",
    "green": "#a6e3a1",
    "teal": "#94e2d5",
    "sky": "#89dceb",
    "sapphire": "#74c7ec",
    "blue": "#89b4fa",
    "lavender": "#b4befe",
    "text": "#cdd6f4",
    "subtext1": "#bac2de",
    "subtext0": "#a6adc8",
    "overlay2": "#9399b2",
    "overlay1": "#7f849c",
    "overlay0": "#6c7086",
    "surface2": "#585b70",
    "surface1": "#45475a",
    "surface0": "#313244",
    "base": "#1e1e2e",
    "mantle": "#181825",
    "crust": "#11111b",
}

_ICONS_CACHE: dict[str, str] | None = None
_CONFIG_CACHE: dict[str, str] | None = None


def _load_from_yaml() -> tuple[dict[str, str], dict[str, str]]:
    """Load icons and config from nerd-font-icons.yml file."""
    from pathlib import Path

    icons = {}
    config = {}
    paths = [
        Path.home() / ".config/kitty/icons.yml",
    ]

    for config_path in paths:
        if not config_path.exists():
            continue
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

            if icons:
                return icons, config
        except Exception:
            continue

    return icons, config


def _ensure_loaded():
    """Ensure icons and config are loaded."""
    global _ICONS_CACHE, _CONFIG_CACHE
    if _ICONS_CACHE is None:
        _ICONS_CACHE, _CONFIG_CACHE = _load_from_yaml()


def _get_icons() -> dict[str, str]:
    """Get icons dict."""
    _ensure_loaded()
    return _ICONS_CACHE or {}


def _get_fallback_icon() -> str:
    """Get fallback icon from config."""
    _ensure_loaded()
    return (_CONFIG_CACHE or {}).get("fallback-icon", "")


def get_icon(exe_name: str) -> str:
    """Get nerd font icon for executable name."""
    icons = _get_icons()
    return icons.get(exe_name, _get_fallback_icon())


_home = os.path.expanduser("~")


def shorten_path(path: str) -> str:
    """Shorten path for display."""
    if path.startswith(_home):
        path = "~" + path[len(_home) :]

    parts = path.strip("/").split("/")
    if len(parts) > MAX_PATH_SEGMENTS:
        parts = [".."] + parts[-MAX_PATH_SEGMENTS:]

    return "/".join(parts)


def get_foreground_process(tab_id: int) -> tuple[str, str]:
    """
    Get the foreground process name and cwd for a tab.
    Returns (exe_name, cwd).

    Uses foreground_processes directly - the delayed redraw timer
    ensures we query after the command has actually started.
    """
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
            # Sort by pid - oldest (lowest) is usually the main command
            procs = sorted(procs, key=lambda p: p.get("pid", 0))

            # Get cwd from oldest process
            cwd = procs[0].get("cwd", "")

            # Find the first non-shell process for the exe
            shells = {"zsh", "bash", "fish", "sh", "nu", "tcsh", "-zsh", "-bash"}
            for proc in procs:
                cmdline = proc.get("cmdline", [])
                if cmdline:
                    proc_exe = os.path.basename(cmdline[0])
                    if proc_exe not in shells:
                        exe = proc_exe
                        break
            else:
                # All processes are shells, use the oldest
                cmdline = procs[0].get("cmdline", [])
                if cmdline:
                    exe = os.path.basename(cmdline[0])
                    # Normalize login shell names: -zsh -> zsh
                    if exe.startswith("-"):
                        exe = exe[1:]
    except Exception:
        pass

    if not cwd:
        from kitty.tab_bar import TabAccessor

        ta = TabAccessor(tab_id)
        cwd = ta.active_wd or ""

    return (exe, cwd)


def format_tab_title(exe: str, cwd: str, index: int) -> str:
    """Format tab title based on DISPLAY_FORMAT setting."""
    icon = get_icon(exe)
    short_path = shorten_path(cwd) if cwd else ""

    if DISPLAY_FORMAT == "icon":
        return f" {icon} "
    elif DISPLAY_FORMAT == "icon+name":
        return f" {icon} {exe} "
    elif DISPLAY_FORMAT == "icon+path":
        return f" {icon} {short_path} " if short_path else f" {icon} {exe} "
    elif DISPLAY_FORMAT == "icon+name+path":
        return f" {icon} {exe} {short_path} " if short_path else f" {icon} {exe} "
    elif DISPLAY_FORMAT == "name+path":
        return f" {exe} {short_path} " if short_path else f" {exe} "
    else:
        return f" {icon} {short_path} "


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
    # Check for delayed refresh request (from shell preexec)
    _check_refresh_request()

    # Get the actual foreground process
    exe, cwd = get_foreground_process(tab.tab_id)

    # Format the title
    title = format_tab_title(exe, cwd, index)

    # Create modified draw_data with our custom title
    new_draw_data = draw_data._replace(
        title_template="{fmt.fg.red}{bell_symbol}{activity_symbol}{fmt.fg.tab}" + title
    )

    return draw_tab_with_powerline(
        new_draw_data,
        screen,
        tab,
        before,
        max_title_length,
        index,
        is_last,
        extra_data,
    )
