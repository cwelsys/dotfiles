#!/usr/bin/env python3
"""
kitty keymaps scrollback overlay.

Usage:
    map ctrl+shift+/ kitten keymap.py
"""

from kittens.tui.handler import result_handler
from kitty import fast_data_types

SHIFT = 1
CTRL = 2
ALT = 4
SUPER = 8

RESET = "\033[0m"
BOLD = "\033[1m"
CYAN = "\033[36m"
GREEN = "\033[32m"

SPECIAL_KEYS = {
    32: "space",
    57344: "esc",
    57345: "enter",
    57346: "tab",
    57347: "backspace",
    57348: "insert",
    57349: "delete",
    57350: "right",
    57351: "left",
    57352: "down",
    57353: "up",
    57354: "page_up",
    57355: "page_down",
    57356: "home",
    57357: "end",
    57358: "caps_lock",
    57359: "scroll_lock",
    57360: "num_lock",
    57361: "print_screen",
    57362: "pause",
    57363: "f1",
    57364: "f2",
    57365: "f3",
    57366: "f4",
    57367: "f5",
    57368: "f6",
    57369: "f7",
    57370: "f8",
    57371: "f9",
    57372: "f10",
    57373: "f11",
    57374: "f12",
}


def format_key(single_key):
    mods = single_key.mods
    key = single_key.key

    parts = []
    if mods & CTRL:
        parts.append("ctrl")
    if mods & ALT:
        parts.append("alt")
    if mods & SHIFT:
        parts.append("shift")
    if mods & SUPER:
        parts.append("cmd")

    if key in SPECIAL_KEYS:
        key_name = SPECIAL_KEYS[key]
    elif 33 <= key <= 126:
        key_name = chr(key)
    else:
        key_name = f"0x{key:x}"

    parts.append(key_name)
    return f"{CYAN}" + "+".join(parts) + f"{RESET}"


def main(args):
    pass


@result_handler(no_ui=True)
def handle_result(args, answer, target_window_id, boss):
    opts = fast_data_types.get_options()
    keyboard_modes = opts.keyboard_modes

    output = []

    for mode_name, mode in keyboard_modes.items():
        if mode_name:
            output.append(f"\n{GREEN}{BOLD}[{mode_name}]{RESET}")
        for trigger, definitions in mode.keymap.items():
            for defn in definitions:
                if defn.definition:
                    key_str = format_key(trigger)
                    output.append(f"  {key_str} → {defn.definition}")

    boss.display_scrollback(
        boss.active_window,
        "\n".join(output),
        title="kitty keys",
        report_cursor=False,
    )
