"""Configuration loader for kitty tab bar.

Provides a unified TOML-based configuration system for tab bar styles,
colors, icons, and behavior. Follows starship.toml conventions.

Color resolution priority:
1. Hex values (#rrggbb)
2. TOML [palette] overrides
3. Kitty terminal colors (color0-15, foreground, background, etc.)
"""

from __future__ import annotations

import os
import sys
import tomllib
from dataclasses import dataclass, field
from functools import lru_cache
from pathlib import Path
from typing import Any

from kitty.fast_data_types import get_options
from kitty.tab_bar import as_rgb
from kitty.utils import color_as_int


@dataclass
class GeneralConfig:
    """General tab bar settings."""

    style: str = "pills"
    extra_shells: list[str] = field(default_factory=list)


@dataclass
class PaletteConfig:
    """Color palette - maps color names to hex values."""

    colors: dict[str, str] = field(default_factory=dict)


@dataclass
class ModeIndicatorPowerlineConfig:
    """Mode indicator colors for powerline style."""

    foreground: str = "color5"  # magenta
    background: str = ""  # empty = inherit tab bar background


@dataclass
class ModeIndicatorPillsConfig:
    """Mode indicator colors for pills style."""

    icon_bg: str = "color5"  # replaces icon_bg_active when mode active
    icon_fg: str = ""  # empty = use icon_fg_active


@dataclass
class ModeIndicatorConfig:
    """Keyboard mode indicator settings."""

    enabled: bool = True
    display_names: dict[str, str] = field(
        default_factory=lambda: {"leader": "\U000f030c"}  # nf-md-keyboard
    )
    powerline: ModeIndicatorPowerlineConfig = field(default_factory=ModeIndicatorPowerlineConfig)
    pills: ModeIndicatorPillsConfig = field(default_factory=ModeIndicatorPillsConfig)


@dataclass
class PowerlineColorsConfig:
    """Powerline style color settings.

    These colors were previously in the top-level [colors] section but are
    specific to powerline style. They're now properly scoped under
    [styles.powerline.colors].
    """

    icon_active: str = "active_tab_foreground"  # Icon color for active tab
    icon_inactive: str = "color4"  # Icon color for inactive tabs (blue)
    path_active_main: str = "active_tab_foreground"  # Current dir in active tab
    rainbow: list[str] = field(
        default_factory=lambda: [
            "color1",  # red
            "color3",  # yellow/peach
            "color11",  # bright yellow
            "color2",  # green
            "color6",  # cyan/teal
            "color4",  # blue
            "color5",  # magenta/lavender
        ]
    )


@dataclass
class PowerlineConfig:
    """Powerline style settings."""

    # These were previously in [general] but are powerline-specific
    rainbow_path: bool = True  # Colorize path segments with rainbow colors
    rainbow_index_icon: bool = True  # Colorize index/icon with rainbow (inactive tabs)
    max_path_segments: int = 2  # Max directory segments to show

    elements: list[str] = field(
        default_factory=lambda: ["index", "hostname", "icon", "path", "ssh"]
    )
    pad_start: str = ""  # kitty's powerline adds its own padding
    pad_end: str = ""  # kitty's powerline adds its own padding
    element_sep: str = " "
    ssh_icon: str = "\ueb3a"  # nf-cod-remote
    colors: PowerlineColorsConfig = field(default_factory=PowerlineColorsConfig)


@dataclass
class PillsColorsConfig:
    """Pills style color settings.

    Uses theme's tab bar colors by default for universal compatibility across
    all kitty themes. The defaults are designed to work whether the theme uses
    light or dark colors for active/inactive tabs.

    Color naming convention:
        - *_bg: Background color for that section
        - *_fg: Foreground (text) color for that section
        - *_active: Used when the tab is the active/focused tab

    Default design rationale:
        - Icon section uses tab colors to indicate active state visually
        - Text section uses consistent background so focus is on icon highlight
        - Foreground colors match their expected backgrounds for contrast
    """

    # Icon section background - shows active state through color change
    icon_bg: str = "inactive_tab_background"  # Muted bg for inactive tabs
    icon_bg_active: str = "active_tab_background"  # Highlighted bg for active tab

    # Icon section foreground - contrasts with respective backgrounds
    icon_fg: str = "foreground"  # Standard text on inactive bg
    icon_fg_active: str = "active_tab_foreground"  # Contrasting text on active bg

    # Text section - consistent background, focus stays on icon
    text_bg: str = "inactive_tab_background"  # Same for all tabs
    text_bg_active: str = "inactive_tab_background"  # Same even when active
    text_fg: str = "foreground"  # Standard text color
    text_fg_active: str = "foreground"  # Same even when active


@dataclass
class GitColorsConfig:
    """Colors for git status parts in left zone.

    Color values use the same resolution as other colors:
    hex values, theme colors, terminal colors, or palette names.
    """

    directory: str = "foreground"  # Directory path
    git_branch_icon: str = "color8"  # Git branch icon (gray)
    git_branch: str = "color5"  # Git branch name (magenta)
    # Git status indicators
    git_stashed: str = "color8"  # * stashed
    git_deleted: str = "color5"  # ✘ deleted
    git_staged: str = "color4"  # + staged
    git_modified: str = "color3"  # ! modified
    git_renamed: str = "color3"  # » renamed
    git_untracked: str = "color4"  # ? untracked
    git_ahead: str = "color2"  # ⇡ ahead
    git_behind: str = "color1"  # ⇣ behind
    git_conflicted: str = "color1"  # ~ conflicted


@dataclass
class PillsLeftZoneConfig:
    """Pills left zone (cwd + git status display) settings."""

    enabled: bool = True
    icon: str = "\uf07c"  # nf-fa-folder_open
    ssh_icon: str = "\ueb3a"  # nf-cod-remote (shown when over SSH)
    max_path_segments: int = 2  # Max directory segments to show in left zone
    use_git: bool = True  # Show git branch and status (mtime-gated)
    git_colors: GitColorsConfig = field(default_factory=GitColorsConfig)


@dataclass
class PillsRightZoneConfig:
    """Pills right zone (pinned tabs) settings."""

    enabled: bool = False
    pinned_processes: list[str] = field(default_factory=list)


@dataclass
class PillsConfig:
    """Pills style settings."""

    border_left: str = "\ue0b6"  # nf-pl-left_hard_divider
    border_right: str = "\ue0b4"  # nf-pl-right_hard_divider
    separator: str = "\ue0b0"  # nf-pl-hard_divider
    spacing: int = 1
    icon_elements: list[str] = field(default_factory=lambda: ["index", "icon"])
    text_elements: list[str] = field(
        default_factory=lambda: ["hostname", "title", "ssh"]
    )
    colors: PillsColorsConfig = field(default_factory=PillsColorsConfig)
    left_zone: PillsLeftZoneConfig = field(default_factory=PillsLeftZoneConfig)
    right_zone: PillsRightZoneConfig = field(default_factory=PillsRightZoneConfig)


@dataclass
class StylesConfig:
    """All style configurations."""

    powerline: PowerlineConfig = field(default_factory=PowerlineConfig)
    pills: PillsConfig = field(default_factory=PillsConfig)


@dataclass
class IconsConfig:
    """Icon configuration."""

    fallback: str = "\uf120"  # nf-fa-terminal
    mapping: dict[str, str] = field(default_factory=dict)


@dataclass
class ShellConfig:
    """Shell integration settings."""

    style_env_var: str = "KITTY_TABBAR_STYLE"


@dataclass
class TabBarConfig:
    """Root configuration container."""

    general: GeneralConfig = field(default_factory=GeneralConfig)
    palette: PaletteConfig = field(default_factory=PaletteConfig)
    mode_indicator: ModeIndicatorConfig = field(default_factory=ModeIndicatorConfig)
    styles: StylesConfig = field(default_factory=StylesConfig)
    icons: IconsConfig = field(default_factory=IconsConfig)
    shell: ShellConfig = field(default_factory=ShellConfig)

    def __post_init__(self):
        pass  # Palette must be loaded from TOML


def _load_terminal_colors() -> dict[str, str]:
    """Load terminal colors at module init (like cool.py does)."""
    colors = {}
    try:
        opts = get_options()
        # Standard 16 colors
        for i in range(16):
            name = f"color{i}"
            color_obj = getattr(opts, name, None)
            if color_obj is not None:
                colors[name] = f"{color_as_int(color_obj):06x}"
        # Extended colors (some themes define color16+)
        for i in range(16, 256):
            name = f"color{i}"
            color_obj = getattr(opts, name, None)
            if color_obj is not None:
                colors[name] = f"{color_as_int(color_obj):06x}"
        # Foreground/background
        for name in ("foreground", "background"):
            color_obj = getattr(opts, name, None)
            if color_obj is not None:
                colors[name] = f"{color_as_int(color_obj):06x}"
        # Tab bar specific colors (from theme)
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


# Pre-load terminal colors at module init (like cool.py does)
_terminal_colors: dict[str, str] = _load_terminal_colors()


# Fallback mappings for tab bar colors that may not be defined in all themes
_COLOR_FALLBACKS: dict[str, str] = {
    "tab_bar_background": "background",
    "active_tab_background": "color4",
    "active_tab_foreground": "color0",
    "inactive_tab_background": "color8",
    "inactive_tab_foreground": "color7",
}

_HEX_CHARS = frozenset("0123456789abcdefABCDEF")

# Valid color name patterns (used for validation)
_VALID_COLOR_NAMES: set[str] = {
    # Terminal colors
    *[f"color{i}" for i in range(256)],
    "foreground",
    "background",
    # Tab bar theme colors
    "active_tab_foreground",
    "active_tab_background",
    "inactive_tab_foreground",
    "inactive_tab_background",
    "tab_bar_background",
}


def _is_valid_hex(s: str) -> bool:
    """Check if string is exactly 6 valid hex characters."""
    return len(s) == 6 and all(c in _HEX_CHARS for c in s)


def _is_valid_color_reference(name: str, palette: dict[str, str]) -> bool:
    """Check if a color name is a valid reference.

    Valid references are:
        - Hex values (#rrggbb or rrggbb)
        - Terminal colors (color0-255, foreground, background)
        - Tab bar theme colors (active_tab_*, inactive_tab_*, tab_bar_background)
        - Palette names (defined in [palette] section)
    """
    if name.startswith("#"):
        return _is_valid_hex(name[1:])
    return _is_valid_hex(name) or name in _VALID_COLOR_NAMES or name in palette


def _validate_color_names(config: "TabBarConfig") -> list[str]:
    """Validate all color references in config, return list of warnings.

    This checks that all color names used in the config resolve to valid colors.
    Invalid names will still work (fallback to gray) but this provides feedback.
    """
    warnings: list[str] = []
    palette = config.palette.colors

    # Collect all color references from config
    color_refs: list[tuple[str, str]] = []  # (location, color_name)

    # From PowerlineColorsConfig (new canonical location)
    pl_colors = config.styles.powerline.colors
    color_refs.extend(
        [
            ("styles.powerline.colors.icon_active", pl_colors.icon_active),
            ("styles.powerline.colors.icon_inactive", pl_colors.icon_inactive),
            ("styles.powerline.colors.path_active_main", pl_colors.path_active_main),
        ]
    )
    for i, color in enumerate(pl_colors.rainbow):
        color_refs.append((f"styles.powerline.colors.rainbow[{i}]", color))

    # From ModeIndicatorConfig
    color_refs.extend(
        [
            ("mode_indicator.powerline.foreground", config.mode_indicator.powerline.foreground),
            ("mode_indicator.powerline.background", config.mode_indicator.powerline.background),
            ("mode_indicator.pills.icon_bg", config.mode_indicator.pills.icon_bg),
            ("mode_indicator.pills.icon_fg", config.mode_indicator.pills.icon_fg),
        ]
    )

    # From PillsColorsConfig
    pills_colors = config.styles.pills.colors
    color_refs.extend(
        [
            ("styles.pills.colors.icon_bg", pills_colors.icon_bg),
            ("styles.pills.colors.icon_bg_active", pills_colors.icon_bg_active),
            ("styles.pills.colors.icon_fg", pills_colors.icon_fg),
            ("styles.pills.colors.icon_fg_active", pills_colors.icon_fg_active),
            ("styles.pills.colors.text_bg", pills_colors.text_bg),
            ("styles.pills.colors.text_bg_active", pills_colors.text_bg_active),
            ("styles.pills.colors.text_fg", pills_colors.text_fg),
            ("styles.pills.colors.text_fg_active", pills_colors.text_fg_active),
        ]
    )

    # Validate each reference (skip empty strings - they mean "unset/inherit")
    for location, name in color_refs:
        if name and not _is_valid_color_reference(name, palette):
            warnings.append(
                f"[tabbar_config] Warning: Unknown color '{name}' at {location}"
            )

    # Print warnings to stderr
    for warning in warnings:
        print(warning, file=sys.stderr)

    return warnings


class ColorResolver:
    """Resolves color names to hex values.

    This is the single source of truth for color resolution. All color lookups
    should go through this class to ensure consistent behavior.

    Resolution priority (highest to lowest):
        1. Hex values (#rrggbb) - returned as-is (stripped of #)
        2. TOML [palette] overrides - user-defined named colors from config
        3. Kitty terminal colors - color0-15, foreground, background
        4. Tab bar theme colors - active_tab_*, inactive_tab_*, tab_bar_background
        5. Fallback mappings - for themes that don't define all tab bar colors
        6. Last resort - return as-is (may be hex without #), warn if invalid

    Example valid color names:
        - "#f38ba8"                  -> Hex value
        - "mauve"                    -> From [palette] section
        - "color4"                   -> Terminal blue
        - "active_tab_foreground"    -> From kitty theme
    """

    def __init__(self, config: TabBarConfig):
        self._palette = config.palette.colors

    def resolve(self, name: str) -> str:
        """Resolve a color name to a hex value (without # prefix).

        Returns gray (cccccc) as fallback for unresolvable names, with a warning.
        """
        # 1. Direct hex value
        if name.startswith("#"):
            hex_part = name[1:]
            if _is_valid_hex(hex_part):
                return hex_part
            self._warn_invalid_color(name, "invalid hex format")
            return "cccccc"

        # 2. TOML palette override
        if name in self._palette:
            return self._palette[name].lstrip("#")

        # 3. Terminal color (pre-loaded at module init)
        if name in _terminal_colors:
            return _terminal_colors[name]

        # 4. Fallback for tab bar colors not in theme
        if name in _COLOR_FALLBACKS:
            fallback = _COLOR_FALLBACKS[name]
            if fallback in _terminal_colors:
                return _terminal_colors[fallback]

        # 5. Check if it's a valid hex without #
        if _is_valid_hex(name):
            return name

        # Unknown color - warn and return gray fallback
        self._warn_invalid_color(name, "unknown color name")
        return "cccccc"

    def _warn_invalid_color(self, name: str, reason: str) -> None:
        """Print warning about invalid color (only once per name)."""
        if not hasattr(self, "_warned_colors"):
            self._warned_colors: set[str] = set()

        if name not in self._warned_colors:
            self._warned_colors.add(name)
            print(
                f"[tabbar_config] Warning: '{name}' - {reason}, using gray fallback",
                file=sys.stderr,
            )

    def as_int(self, name: str) -> int:
        """Resolve color name to RGB integer for screen.cursor."""
        try:
            return as_rgb(int(self.resolve(name), 16))
        except ValueError:
            # Fallback to white if color can't be resolved
            return as_rgb(0xCCCCCC)


class UnifiedColorResolver:
    """Single source of truth for color resolution with live DrawData support.

    This resolver combines:
    - Static config colors (palette, terminal colors)
    - Live DrawData colors (theme colors that update with theme changes)

    Resolution priority (highest to lowest):
        1. Hex values (#rrggbb) - returned as-is
        2. DrawData colors (live theme: active_tab_*, inactive_tab_*, etc.)
        3. TOML [palette] overrides - user-defined named colors
        4. Terminal colors (color0-15, foreground, background)
        5. Fallback mappings - for themes missing tab bar colors
        6. Warning + gray default

    Usage:
        # Create with DrawData during render
        resolver = UnifiedColorResolver(config, draw_data)

        # Resolve to hex string (for {fmt.fg._RRGGBB})
        hex_color = resolver.resolve_to_hex("mauve")

        # Resolve to int (for screen.cursor.fg/bg)
        int_color = resolver.resolve_to_int("active_tab_foreground")
    """

    def __init__(self, config: TabBarConfig, draw_data=None):
        """Initialize with config and optional DrawData.

        Args:
            config: TabBarConfig with palette and color settings
            draw_data: Optional kitty DrawData for live theme colors
        """
        self._palette = config.palette.colors
        self._draw_data_colors: dict[str, int] = {}
        self._warned_colors: set[str] = set()

        # Extract live colors from DrawData if provided
        if draw_data is not None:
            self._draw_data_colors = {
                "active_tab_foreground": as_rgb(int(draw_data.active_fg)),
                "active_tab_background": as_rgb(int(draw_data.active_bg)),
                "inactive_tab_foreground": as_rgb(int(draw_data.inactive_fg)),
                "inactive_tab_background": as_rgb(int(draw_data.inactive_bg)),
                "tab_bar_background": as_rgb(int(draw_data.default_bg)),
            }

    def resolve_to_hex(self, name: str) -> str:
        """Resolve color name to hex value (without # prefix).

        Use this for format strings like {fmt.fg._RRGGBB}.
        """
        # 1. Direct hex value
        if name.startswith("#"):
            hex_part = name[1:]
            if _is_valid_hex(hex_part):
                return hex_part
            self._warn_invalid_color(name, "invalid hex format")
            return "cccccc"

        # 2. DrawData colors (live theme - highest priority for tab bar colors)
        if name in self._draw_data_colors:
            # as_rgb() adds a flag byte (x << 8 | 2), shift right to get RGB
            return f"{self._draw_data_colors[name] >> 8:06x}"

        # 3. TOML palette override
        if name in self._palette:
            return self._palette[name].lstrip("#")

        # 4. Terminal color (pre-loaded at module init)
        if name in _terminal_colors:
            return _terminal_colors[name]

        # 5. Fallback for tab bar colors not in theme
        if name in _COLOR_FALLBACKS:
            fallback = _COLOR_FALLBACKS[name]
            if fallback in _terminal_colors:
                return _terminal_colors[fallback]

        # 6. Check if it's a valid hex without #
        if _is_valid_hex(name):
            return name

        # Unknown color - warn and return gray fallback
        self._warn_invalid_color(name, "unknown color name")
        return "cccccc"

    def resolve_to_int(self, name: str) -> int:
        """Resolve color name to RGB integer for screen.cursor.

        Use this for screen.cursor.fg and screen.cursor.bg.
        """
        # Check DrawData first for live theme colors (already int)
        if name in self._draw_data_colors:
            return self._draw_data_colors[name]

        # Fall back to hex resolution
        try:
            return as_rgb(int(self.resolve_to_hex(name), 16))
        except ValueError:
            return as_rgb(0xCCCCCC)

    def _warn_invalid_color(self, name: str, reason: str) -> None:
        """Print warning about invalid color (only once per name)."""
        if name not in self._warned_colors:
            self._warned_colors.add(name)
            print(
                f"[tabbar_config] Warning: '{name}' - {reason}, using gray fallback",
                file=sys.stderr,
            )


def _parse_toml(data: dict[str, Any]) -> TabBarConfig:
    """Parse TOML dict into TabBarConfig."""
    config = TabBarConfig()

    # General section
    if "general" in data:
        gen = data["general"]
        config.general.style = gen.get("style", config.general.style)
        if "extra_shells" in gen:
            config.general.extra_shells = gen["extra_shells"]

    # Palette section - colors are stored directly under [palette]
    if "palette" in data:
        config.palette.colors = data["palette"]

    # Mode indicator section
    if "mode_indicator" in data:
        mi = data["mode_indicator"]
        config.mode_indicator.enabled = mi.get("enabled", config.mode_indicator.enabled)
        if "display_names" in mi:
            config.mode_indicator.display_names = mi["display_names"]

        # Powerline-specific mode indicator settings
        if "powerline" in mi:
            pl_mi = mi["powerline"]
            config.mode_indicator.powerline.foreground = pl_mi.get(
                "foreground", config.mode_indicator.powerline.foreground
            )
            config.mode_indicator.powerline.background = pl_mi.get(
                "background", config.mode_indicator.powerline.background
            )

        # Pills-specific mode indicator settings
        if "pills" in mi:
            pi_mi = mi["pills"]
            config.mode_indicator.pills.icon_bg = pi_mi.get(
                "icon_bg", config.mode_indicator.pills.icon_bg
            )
            config.mode_indicator.pills.icon_fg = pi_mi.get(
                "icon_fg", config.mode_indicator.pills.icon_fg
            )

    # Styles section
    if "styles" in data:
        styles = data["styles"]

        # Powerline
        if "powerline" in styles:
            pl = styles["powerline"]

            if "rainbow_path" in pl:
                config.styles.powerline.rainbow_path = pl["rainbow_path"]
            if "rainbow_index_icon" in pl:
                config.styles.powerline.rainbow_index_icon = pl["rainbow_index_icon"]
            if "max_path_segments" in pl:
                config.styles.powerline.max_path_segments = pl["max_path_segments"]

            if "elements" in pl:
                config.styles.powerline.elements = pl["elements"]
            config.styles.powerline.pad_start = pl.get(
                "pad_start", config.styles.powerline.pad_start
            )
            config.styles.powerline.pad_end = pl.get(
                "pad_end", config.styles.powerline.pad_end
            )
            config.styles.powerline.element_sep = pl.get(
                "element_sep", config.styles.powerline.element_sep
            )
            if "ssh_icon" in pl:
                config.styles.powerline.ssh_icon = pl["ssh_icon"]

            if "colors" in pl:
                pc = pl["colors"]
                if "icon_active" in pc:
                    config.styles.powerline.colors.icon_active = pc["icon_active"]
                if "icon_inactive" in pc:
                    config.styles.powerline.colors.icon_inactive = pc["icon_inactive"]
                if "path_active_main" in pc:
                    config.styles.powerline.colors.path_active_main = pc[
                        "path_active_main"
                    ]
                if "rainbow" in pc:
                    config.styles.powerline.colors.rainbow = pc["rainbow"]

        # Pills
        if "pills" in styles:
            pi = styles["pills"]
            config.styles.pills.border_left = pi.get(
                "border_left", config.styles.pills.border_left
            )
            config.styles.pills.border_right = pi.get(
                "border_right", config.styles.pills.border_right
            )
            config.styles.pills.separator = pi.get(
                "separator", config.styles.pills.separator
            )
            config.styles.pills.spacing = pi.get("spacing", config.styles.pills.spacing)
            if "icon_elements" in pi:
                config.styles.pills.icon_elements = pi["icon_elements"]
            if "text_elements" in pi:
                config.styles.pills.text_elements = pi["text_elements"]

            # Pills colors
            if "colors" in pi:
                pc = pi["colors"]
                config.styles.pills.colors.icon_bg = pc.get(
                    "icon_bg", config.styles.pills.colors.icon_bg
                )
                config.styles.pills.colors.icon_bg_active = pc.get(
                    "icon_bg_active", config.styles.pills.colors.icon_bg_active
                )
                config.styles.pills.colors.text_bg = pc.get(
                    "text_bg", config.styles.pills.colors.text_bg
                )
                config.styles.pills.colors.text_bg_active = pc.get(
                    "text_bg_active", config.styles.pills.colors.text_bg_active
                )
                config.styles.pills.colors.icon_fg = pc.get(
                    "icon_fg", config.styles.pills.colors.icon_fg
                )
                config.styles.pills.colors.text_fg = pc.get(
                    "text_fg", config.styles.pills.colors.text_fg
                )
                config.styles.pills.colors.text_fg_active = pc.get(
                    "text_fg_active", config.styles.pills.colors.text_fg_active
                )
                config.styles.pills.colors.icon_fg_active = pc.get(
                    "icon_fg_active", config.styles.pills.colors.icon_fg_active
                )

            # Pills left zone
            if "left_zone" in pi:
                lz = pi["left_zone"]
                config.styles.pills.left_zone.enabled = lz.get(
                    "enabled", config.styles.pills.left_zone.enabled
                )
                config.styles.pills.left_zone.icon = lz.get(
                    "icon", config.styles.pills.left_zone.icon
                )
                config.styles.pills.left_zone.ssh_icon = lz.get(
                    "ssh_icon", config.styles.pills.left_zone.ssh_icon
                )
                if "max_path_segments" in lz:
                    config.styles.pills.left_zone.max_path_segments = lz[
                        "max_path_segments"
                    ]
                config.styles.pills.left_zone.use_git = lz.get(
                    "use_git", config.styles.pills.left_zone.use_git
                )

                # Git colors - update fields present in TOML
                if "git_colors" in lz:
                    gc = lz["git_colors"]
                    colors = config.styles.pills.left_zone.git_colors
                    for color_field in (
                        "directory", "git_branch_icon", "git_branch",
                        "git_stashed", "git_deleted", "git_staged", "git_modified",
                        "git_renamed", "git_untracked", "git_ahead", "git_behind",
                        "git_conflicted",
                    ):
                        if color_field in gc:
                            setattr(colors, color_field, gc[color_field])

            # Pills right zone
            if "right_zone" in pi:
                rz = pi["right_zone"]
                config.styles.pills.right_zone.enabled = rz.get(
                    "enabled", config.styles.pills.right_zone.enabled
                )
                if "pinned_processes" in rz:
                    config.styles.pills.right_zone.pinned_processes = rz[
                        "pinned_processes"
                    ]

    # Icons section
    if "icons" in data:
        ic = data["icons"]
        config.icons.fallback = ic.get("fallback", config.icons.fallback)
        if "mapping" in ic:
            config.icons.mapping = ic["mapping"]

    # Shell section
    if "shell" in data:
        sh = data["shell"]
        config.shell.style_env_var = sh.get("style_env_var", config.shell.style_env_var)

    return config


def _load_config() -> TabBarConfig:
    """Load configuration from tabbar.toml with fallbacks.

    Validates color references and prints warnings for unknown colors.
    """
    config_path = Path.home() / ".config/kitty/tabbar.toml"

    if config_path.exists():
        try:
            with open(config_path, "rb") as f:
                data = tomllib.load(f)
            config = _parse_toml(data)
            print(
                f"[tabbar_config] Loaded config: style={config.general.style}",
                file=sys.stderr,
            )
        except Exception as e:
            import traceback

            print(f"[tabbar_config] ERROR loading config: {e}", file=sys.stderr)
            traceback.print_exc(file=sys.stderr)
            config = TabBarConfig()
    else:
        print(f"[tabbar_config] Config file not found: {config_path}", file=sys.stderr)
        config = TabBarConfig()

    # Validate color references (prints warnings to stderr)
    _validate_color_names(config)

    return config


# Cached config singleton
_config_cache: TabBarConfig | None = None
_color_resolver_cache: ColorResolver | None = None


def get_config() -> TabBarConfig:
    """Get the cached configuration."""
    global _config_cache
    if _config_cache is None:
        _config_cache = _load_config()
    return _config_cache


def get_color_resolver() -> ColorResolver:
    """Get the cached color resolver."""
    global _color_resolver_cache
    if _color_resolver_cache is None:
        _color_resolver_cache = ColorResolver(get_config())
    return _color_resolver_cache


def get_active_style() -> str:
    """Get the active tab bar style, checking env var override."""
    config = get_config()
    env_var = config.shell.style_env_var

    # Check environment variable override
    env_style = os.environ.get(env_var, "").lower()
    if env_style in ("pills", "powerline"):
        return env_style

    return config.general.style


def get_icon(exe_name: str) -> str:
    """Get icon for an executable name."""
    config = get_config()
    return config.icons.mapping.get(exe_name, config.icons.fallback)


def reload_config():
    """Force reload of configuration (for development/debugging)."""
    global _config_cache, _color_resolver_cache
    _config_cache = None
    _color_resolver_cache = None
