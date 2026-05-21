"""Configuration loader for kitty tab bar.

Color resolution priority:
1. Hex values (#rrggbb)
2. TOML [palette] overrides
3. Kitty terminal colors (color0-15, foreground, background, etc.)

All glyphs (pill borders, zone icons, status symbols, ellipsis) and all
specific color picks live in tabbar.toml. Python dataclass defaults are
semantic fallbacks (theme references like "foreground" or empty strings)
— never literal glyphs or specific palette picks.
"""

from __future__ import annotations

import sys
import tomllib
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any

from kitty.fast_data_types import get_options
from kitty.tab_bar import as_rgb
from kitty.utils import color_as_int


@dataclass
class PaletteConfig:
    """Color palette — maps color names to hex values."""

    colors: dict[str, str] = field(default_factory=dict)


@dataclass
class ModeIndicatorConfig:
    """Keyboard mode indicator settings."""

    enabled: bool = True
    bg: str = ""  # empty = use bar.active_bg
    fg: str = ""  # empty = use bar.active_fg
    display_names: dict[str, str] = field(default_factory=dict)


@dataclass
class BarConfig:
    """Bar styling — chrome glyphs and pill colors.

    Border/separator glyphs default to empty (set in tabbar.toml). Color
    defaults are theme references — they pull from the active kitty theme's
    tab bar colors rather than specific palette picks.

    Color naming:
        active_*        active tab pill icon section + zone icon section
        inactive_*      inactive tab pill icon section
        text_*          zone text section (no inactive variant — tab pills have no text)
    """

    border_left: str = ""
    border_right: str = ""
    separator: str = ""
    spacing: int = 1
    icon_elements: list[str] = field(default_factory=lambda: ["index", "icon"])
    active_bg: str = "active_tab_background"
    active_fg: str = "active_tab_foreground"
    inactive_bg: str = "inactive_tab_background"
    inactive_fg: str = "foreground"
    text_bg: str = "inactive_tab_background"
    text_fg: str = "foreground"


@dataclass
class GitSymbolsConfig:
    """Glyphs/symbols for the `git` content kind.

    All defaults are empty — set them in tabbar.toml under [git.symbols].
    """

    branch_icon: str = ""
    stashed: str = ""
    deleted: str = ""
    staged: str = ""
    modified: str = ""
    renamed: str = ""
    untracked: str = ""
    conflicted: str = ""
    ahead: str = ""
    behind: str = ""


@dataclass
class GitConfig:
    """Colors and symbols for the `git` content kind (and `cwd_git`).

    Color defaults are theme references (`foreground`); specific palette
    picks live in tabbar.toml under [git]. Symbols live under [git.symbols].
    """

    directory: str = "foreground"
    branch_icon: str = "foreground"
    branch: str = "foreground"
    stashed: str = "foreground"
    deleted: str = "foreground"
    staged: str = "foreground"
    modified: str = "foreground"
    renamed: str = "foreground"
    untracked: str = "foreground"
    ahead: str = "foreground"
    behind: str = "foreground"
    conflicted: str = "foreground"
    symbols: GitSymbolsConfig = field(default_factory=GitSymbolsConfig)


@dataclass
class ZoneConfig:
    """A tab-bar zone (left or right).

    `content` is a list of content kinds rendered in order, joined by
    the top-level `content_separator` when multiple kinds are present.
    Known kinds: "cwd", "git", "cwd_git", "title", "tab_label". Empty
    list disables the zone. TOML accepts a bare string as shorthand for
    a one-element list.
    """

    content: list[str] = field(default_factory=list)
    icon: str = ""
    ssh_icon: str = ""  # shown over SSH; empty leaves icon unchanged
    truncation: str = "end"
    min_text_budget: int = 4
    show_mode_indicator: bool = False


@dataclass
class IconsConfig:
    """Icon configuration."""

    fallback: str = ""
    mapping: dict[str, str] = field(default_factory=dict)


@dataclass
class TabBarConfig:
    """Root configuration — flat top-level peers."""

    extra_shells: list[str] = field(default_factory=list)
    sticky_last_cmd: bool = False
    content_separator: str = " · "
    ellipsis: str = ""
    palette: PaletteConfig = field(default_factory=PaletteConfig)
    left_zone: ZoneConfig = field(
        default_factory=lambda: ZoneConfig(content=["cwd_git"])
    )
    right_zone: ZoneConfig = field(default_factory=ZoneConfig)
    git: GitConfig = field(default_factory=GitConfig)
    bar: BarConfig = field(default_factory=BarConfig)
    mode_indicator: ModeIndicatorConfig = field(default_factory=ModeIndicatorConfig)
    icons: IconsConfig = field(default_factory=IconsConfig)


def _load_terminal_colors() -> dict[str, str]:
    """Snapshot terminal colors from kitty options at module init."""
    colors = {}
    try:
        opts = get_options()
        for i in range(16):
            name = f"color{i}"
            color_obj = getattr(opts, name, None)
            if color_obj is not None:
                colors[name] = f"{color_as_int(color_obj):06x}"
        for i in range(16, 256):
            name = f"color{i}"
            color_obj = getattr(opts, name, None)
            if color_obj is not None:
                colors[name] = f"{color_as_int(color_obj):06x}"
        for name in ("foreground", "background"):
            color_obj = getattr(opts, name, None)
            if color_obj is not None:
                colors[name] = f"{color_as_int(color_obj):06x}"
        for name in (
            "active_tab_foreground",
            "active_tab_background",
            "inactive_tab_foreground",
            "inactive_tab_background",
            "tab_bar_background",
        ):
            color_obj = getattr(opts, name, None)
            if color_obj is not None:
                colors[name] = f"{color_as_int(color_obj):06x}"
    except Exception:
        pass
    return colors


_terminal_colors: dict[str, str] = _load_terminal_colors()


_COLOR_FALLBACKS: dict[str, str] = {
    "tab_bar_background": "background",
    "active_tab_background": "color4",
    "active_tab_foreground": "color0",
    "inactive_tab_background": "color8",
    "inactive_tab_foreground": "color7",
}

_HEX_CHARS = frozenset("0123456789abcdefABCDEF")

_VALID_COLOR_NAMES: set[str] = {
    *[f"color{i}" for i in range(256)],
    "foreground",
    "background",
    "active_tab_foreground",
    "active_tab_background",
    "inactive_tab_foreground",
    "inactive_tab_background",
    "tab_bar_background",
}


def _is_valid_hex(s: str) -> bool:
    return len(s) == 6 and all(c in _HEX_CHARS for c in s)


def _is_valid_color_reference(name: str, palette: dict[str, str]) -> bool:
    """Check if a color name is a valid reference."""
    if name.startswith("#"):
        return _is_valid_hex(name[1:])
    return _is_valid_hex(name) or name in _VALID_COLOR_NAMES or name in palette


_GIT_COLOR_FIELDS: tuple[str, ...] = (
    "directory",
    "branch_icon",
    "branch",
    "stashed",
    "deleted",
    "staged",
    "modified",
    "renamed",
    "untracked",
    "ahead",
    "behind",
    "conflicted",
)

_GIT_SYMBOL_FIELDS: tuple[str, ...] = (
    "branch_icon",
    "stashed",
    "deleted",
    "staged",
    "modified",
    "renamed",
    "untracked",
    "conflicted",
    "ahead",
    "behind",
)

# Status fields paired with the git color used when rendering counts.
_GIT_STATUS_FIELDS: tuple[str, ...] = (
    "stashed",
    "deleted",
    "staged",
    "modified",
    "renamed",
    "untracked",
    "conflicted",
    "ahead",
    "behind",
)


def _validate_color_names(config: "TabBarConfig") -> list[str]:
    """Validate all color references in config, return list of warnings."""
    warnings: list[str] = []
    palette = config.palette.colors
    color_refs: list[tuple[str, str]] = []

    color_refs.extend(
        [
            ("mode_indicator.bg", config.mode_indicator.bg),
            ("mode_indicator.fg", config.mode_indicator.fg),
        ]
    )

    bar = config.bar
    color_refs.extend(
        [
            ("bar.active_bg", bar.active_bg),
            ("bar.active_fg", bar.active_fg),
            ("bar.inactive_bg", bar.inactive_bg),
            ("bar.inactive_fg", bar.inactive_fg),
            ("bar.text_bg", bar.text_bg),
            ("bar.text_fg", bar.text_fg),
        ]
    )

    for f in _GIT_COLOR_FIELDS:
        color_refs.append((f"git.{f}", getattr(config.git, f)))

    for location, name in color_refs:
        if name and not _is_valid_color_reference(name, palette):
            warnings.append(
                f"[tabbar_config] Warning: Unknown color '{name}' at {location}"
            )

    for warning in warnings:
        print(warning, file=sys.stderr)

    return warnings


class UnifiedColorResolver:
    """Resolve color names to hex strings or RGB ints.

    Combines static config (palette, terminal colors) with live DrawData
    colors that follow theme changes.

    Resolution priority (highest first):
        1. Hex values (#rrggbb)
        2. DrawData colors (active_tab_*, inactive_tab_*, tab_bar_background)
        3. TOML [palette] overrides
        4. Terminal colors (color0-255, foreground, background)
        5. Fallback mappings for themes missing tab bar colors
        6. Warn and return gray
    """

    def __init__(self, config: TabBarConfig, draw_data=None):
        self._palette = config.palette.colors
        self._draw_data_colors: dict[str, int] = {}
        self._warned_colors: set[str] = set()

        if draw_data is not None:
            self._draw_data_colors = {
                "active_tab_foreground": as_rgb(int(draw_data.active_fg)),
                "active_tab_background": as_rgb(int(draw_data.active_bg)),
                "inactive_tab_foreground": as_rgb(int(draw_data.inactive_fg)),
                "inactive_tab_background": as_rgb(int(draw_data.inactive_bg)),
                "tab_bar_background": as_rgb(int(draw_data.default_bg)),
            }

    def resolve_to_hex(self, name: str) -> str:
        if name.startswith("#"):
            hex_part = name[1:]
            if _is_valid_hex(hex_part):
                return hex_part
            self._warn_invalid_color(name, "invalid hex format")
            return "cccccc"

        if name in self._draw_data_colors:
            return f"{self._draw_data_colors[name] >> 8:06x}"

        if name in self._palette:
            return self._palette[name].lstrip("#")

        if name in _terminal_colors:
            return _terminal_colors[name]

        if name in _COLOR_FALLBACKS:
            fallback = _COLOR_FALLBACKS[name]
            if fallback in _terminal_colors:
                return _terminal_colors[fallback]

        if _is_valid_hex(name):
            return name

        self._warn_invalid_color(name, "unknown color name")
        return "cccccc"

    def resolve_to_int(self, name: str) -> int:
        if name in self._draw_data_colors:
            return self._draw_data_colors[name]

        try:
            return as_rgb(int(self.resolve_to_hex(name), 16))
        except ValueError:
            return as_rgb(0xCCCCCC)

    def _warn_invalid_color(self, name: str, reason: str) -> None:
        if name not in self._warned_colors:
            self._warned_colors.add(name)
            print(
                f"[tabbar_config] Warning: '{name}' - {reason}, using gray fallback",
                file=sys.stderr,
            )


def _normalize_content(value):
    """Accept either a string or a list; always return a list of strings."""
    if isinstance(value, str):
        return [value] if value else []
    if isinstance(value, list):
        return [str(v) for v in value]
    return []


def _apply_zone(zone: ZoneConfig, toml: dict[str, Any]) -> None:
    """Apply TOML keys to a zone, leaving unset keys at their defaults."""
    if "content" in toml:
        zone.content = _normalize_content(toml["content"])
    for key in ("icon", "ssh_icon", "truncation"):
        if key in toml:
            setattr(zone, key, toml[key])
    if "min_text_budget" in toml:
        zone.min_text_budget = toml["min_text_budget"]
    if "show_mode_indicator" in toml:
        zone.show_mode_indicator = toml["show_mode_indicator"]


def _parse_toml(data: dict[str, Any]) -> TabBarConfig:
    """Parse TOML dict into TabBarConfig."""
    config = TabBarConfig()

    for key in ("extra_shells", "sticky_last_cmd", "content_separator", "ellipsis"):
        if key in data:
            setattr(config, key, data[key])

    if "palette" in data:
        config.palette.colors = data["palette"]

    if "left_zone" in data:
        _apply_zone(config.left_zone, data["left_zone"])
    if "right_zone" in data:
        _apply_zone(config.right_zone, data["right_zone"])

    if "git" in data:
        gc = data["git"]
        for key in _GIT_COLOR_FIELDS:
            if key in gc:
                setattr(config.git, key, gc[key])
        if "symbols" in gc:
            sym = gc["symbols"]
            for key in _GIT_SYMBOL_FIELDS:
                if key in sym:
                    setattr(config.git.symbols, key, sym[key])

    if "bar" in data:
        bar = data["bar"]
        for key in (
            "border_left",
            "border_right",
            "separator",
            "spacing",
            "active_bg",
            "active_fg",
            "inactive_bg",
            "inactive_fg",
            "text_bg",
            "text_fg",
        ):
            if key in bar:
                setattr(config.bar, key, bar[key])
        if "icon_elements" in bar:
            config.bar.icon_elements = bar["icon_elements"]

    if "mode_indicator" in data:
        mi = data["mode_indicator"]
        for key in ("enabled", "bg", "fg"):
            if key in mi:
                setattr(config.mode_indicator, key, mi[key])
        if "display_names" in mi:
            config.mode_indicator.display_names = mi["display_names"]

    if "icons" in data:
        ic = data["icons"]
        if "fallback" in ic:
            config.icons.fallback = ic["fallback"]
        if "mapping" in ic:
            config.icons.mapping = ic["mapping"]

    return config


def _load_config() -> TabBarConfig:
    """Load configuration from tabbar.toml with fallbacks."""
    config_path = Path.home() / ".config/kitty/tabbar.toml"

    if config_path.exists():
        try:
            with open(config_path, "rb") as f:
                data = tomllib.load(f)
            config = _parse_toml(data)
        except Exception as e:
            import traceback

            print(f"[tabbar_config] ERROR loading config: {e}", file=sys.stderr)
            traceback.print_exc(file=sys.stderr)
            config = TabBarConfig()
    else:
        print(f"[tabbar_config] Config file not found: {config_path}", file=sys.stderr)
        config = TabBarConfig()

    _validate_color_names(config)

    return config


_config_cache: TabBarConfig | None = None


def get_config() -> TabBarConfig:
    """Get the cached configuration."""
    global _config_cache
    if _config_cache is None:
        _config_cache = _load_config()
    return _config_cache


def get_icon(exe_name: str) -> str:
    """Get icon for an executable name."""
    config = get_config()
    return config.icons.mapping.get(exe_name, config.icons.fallback)


def reload_config():
    """Force reload of configuration (for development/debugging)."""
    global _config_cache
    _config_cache = None
