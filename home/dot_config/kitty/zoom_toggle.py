#!/usr/bin/env python3
"""
Zoom toggle - switches between stack (zoomed) and splits layout.
Only toggles if there's more than one window in the tab.
"""

def main(args):
    pass

from kittens.tui.handler import result_handler

@result_handler(no_ui=True)
def handle_result(args, answer, target_window_id, boss):
    tab = boss.active_tab
    if tab is not None:
        if len(tab.windows) > 1:
            if tab.current_layout.name == 'stack':
                tab.goto_layout('splits')
            else:
                tab.goto_layout('stack')
