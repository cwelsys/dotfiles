#!/usr/bin/env python3
"""
Pin-aware tab/window management for kitty.

Usage:
    kitten klonopin.py pin              # Pin current tab (move to end)
    kitten klonopin.py unpin            # Unpin current tab (move to start)
    kitten klonopin.py close-tab        # Close tab (skip if pinned, go to prev non-pinned)
    kitten klonopin.py close-window     # Close window (skip if pinned)
    kitten klonopin.py new-tab          # New tab before pinned tabs (inherit cwd)
    kitten klonopin.py new-tab --local  # New tab before pinned tabs (no cwd)
    kitten klonopin.py move-left        # Move tab left (pinned tabs stay at end)
    kitten klonopin.py move-right       # Move tab right (can't cross into pinned zone)
"""

from kittens.tui.handler import result_handler


def main(args):
    pass


def is_tab_pinned(tab):
    """Check if any window in tab has PINNED set."""
    for w in tab:
        if w.user_vars.get("PINNED"):
            return True
    return False


def find_first_pinned_idx(tm):
    """Find index of first pinned tab, or None if no pinned tabs."""
    for i, tab in enumerate(tm.tabs):
        if is_tab_pinned(tab):
            return i
    return None


def find_prev_non_pinned_idx(tm, current_idx):
    """Find index of previous non-pinned tab, or first non-pinned if at start."""
    tabs = list(tm.tabs)

    # Look backwards from current
    for i in range(current_idx - 1, -1, -1):
        if not is_tab_pinned(tabs[i]):
            return i

    # If no previous, find first non-pinned after current
    for i in range(current_idx + 1, len(tabs)):
        if not is_tab_pinned(tabs[i]):
            return i

    return None


def do_pin(boss):
    """Pin current tab - move to end and set PINNED var."""
    tab = boss.active_tab
    if tab is None:
        return

    window = tab.active_window
    if window is None:
        return

    tm = boss.active_tab_manager
    if tm is None:
        return

    tabs = list(tm.tabs)
    current_idx = tabs.index(tab)
    total_tabs = len(tabs)

    moves_needed = total_tabs - 1 - current_idx
    for _ in range(moves_needed):
        tm.move_tab(1)

    window.set_user_var("PINNED", "true")


def do_unpin(boss):
    """Unpin current tab - clear PINNED var and move to start."""
    tab = boss.active_tab
    if tab is None:
        return

    window = tab.active_window
    if window is None:
        return

    tm = boss.active_tab_manager
    if tm is None:
        return

    window.set_user_var("PINNED", None)

    tabs = list(tm.tabs)
    current_idx = tabs.index(tab)
    for _ in range(current_idx):
        tm.move_tab(-1)


def do_close_tab(boss, target_window_id):
    """Close tab if not pinned, navigate to previous non-pinned tab."""
    window = boss.window_id_map.get(target_window_id)
    if window is None:
        return

    tab = window.tabref()
    if tab is None:
        return

    if is_tab_pinned(tab):
        return

    tm = boss.active_tab_manager
    if tm is None:
        return

    tabs = list(tm.tabs)
    current_idx = tabs.index(tab)

    # Find where to go after closing
    next_idx = find_prev_non_pinned_idx(tm, current_idx)

    # Activate next tab before closing (if different and exists)
    if next_idx is not None and next_idx != current_idx:
        tm.set_active_tab_idx(next_idx)

    boss.close_tab_no_confirm(tab)


def do_close_window(boss, target_window_id):
    """Close window if not pinned. If last window in tab, navigate like close-tab."""
    window = boss.window_id_map.get(target_window_id)
    if window is None:
        return

    if window.user_vars.get("PINNED"):
        return

    tab = window.tabref()
    if tab is None:
        boss.mark_window_for_close(window)
        return

    # If this is the last window in the tab, handle like close-tab
    if len(list(tab)) == 1:
        tm = boss.active_tab_manager
        if tm is not None:
            tabs = list(tm.tabs)
            current_idx = tabs.index(tab)
            next_idx = find_prev_non_pinned_idx(tm, current_idx)
            if next_idx is not None and next_idx != current_idx:
                tm.set_active_tab_idx(next_idx)

    boss.mark_window_for_close(window)


def do_new_tab(boss, local_mode):
    """Open new tab before pinned tabs."""
    from kitty.window import CwdRequest

    tm = boss.active_tab_manager
    if tm is None:
        return

    # Get cwd from current window (unless local mode)
    cwd_request = None
    if not local_mode:
        current_window = boss.active_window
        cwd_request = CwdRequest(current_window) if current_window else None

    # Find first pinned tab position
    first_pinned_idx = find_first_pinned_idx(tm)

    # Open new tab
    tm.new_tab(cwd_from=cwd_request)

    # If there are pinned tabs, move the new tab before them
    if first_pinned_idx is not None:
        tabs = list(tm.tabs)
        current_idx = len(tabs) - 1  # new tab is at end
        moves_needed = current_idx - first_pinned_idx
        for _ in range(moves_needed):
            tm.move_tab(-1)


def do_move_left(boss):
    """Move current tab left, respecting pinned tab boundaries."""
    tab = boss.active_tab
    if tab is None:
        return

    tm = boss.active_tab_manager
    if tm is None:
        return

    tabs = list(tm.tabs)
    current_idx = tabs.index(tab)

    # Can't move left if already at start
    if current_idx == 0:
        return

    # Pinned tabs can't move left (they must stay at the end)
    if is_tab_pinned(tab):
        first_pinned_idx = find_first_pinned_idx(tm)
        if first_pinned_idx is not None and current_idx == first_pinned_idx:
            return  # Already at the left edge of pinned zone

    tm.move_tab(-1)


def do_move_right(boss):
    """Move current tab right, respecting pinned tab boundaries."""
    tab = boss.active_tab
    if tab is None:
        return

    tm = boss.active_tab_manager
    if tm is None:
        return

    tabs = list(tm.tabs)
    current_idx = tabs.index(tab)
    total_tabs = len(tabs)

    # Can't move right if already at end
    if current_idx >= total_tabs - 1:
        return

    # Non-pinned tabs can't cross into pinned zone
    if not is_tab_pinned(tab):
        first_pinned_idx = find_first_pinned_idx(tm)
        if first_pinned_idx is not None and current_idx >= first_pinned_idx - 1:
            return  # Would cross into pinned zone

    tm.move_tab(1)


@result_handler(no_ui=True)
def handle_result(args, answer, target_window_id, boss):
    if not args or len(args) < 2:
        return

    action = args[1]

    if action == "pin":
        do_pin(boss)
    elif action == "unpin":
        do_unpin(boss)
    elif action == "close-tab":
        do_close_tab(boss, target_window_id)
    elif action == "close-window":
        do_close_window(boss, target_window_id)
    elif action == "new-tab":
        local_mode = "--local" in args
        do_new_tab(boss, local_mode)
    elif action == "move-left":
        do_move_left(boss)
    elif action == "move-right":
        do_move_right(boss)
