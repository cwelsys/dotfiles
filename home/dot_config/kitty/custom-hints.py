#!/usr/bin/env python3
"""
Custom hints for selecting URLs, paths, and common filenames.
Similar to tmux-fingers.
"""

import re
from kitty.clipboard import set_clipboard_string

RE_PATH = (
    r'(?=[ \t\n]|"|\(|\[|<|\')?'
    '(~/|/)?'
    '([-a-zA-Z0-9_+-,.]+/[^ \t\n\r|:"\'$%&)>\]]*)'
)

RE_URL = (
    r"(https?://|git@|git://|ssh://|s*ftp://|file:///)"
    r"[a-zA-Z0-9?=%/_.:,;~@!#$&()*+-]*"
)

RE_COMMON_FILENAME = (
    r'\s?([a-zA-Z0-9_.-/]*[a-zA-Z0-9_.-]+\.'
    r'(ini|yml|yaml|vim|toml|conf|lua|go|php|rs|py|js|ts|tsx|jsx|'
    r'vue|html|htm|md|mp3|wav|flac|mp4|mkv|dll|exe|sh|txt|log|gz|'
    r'tar|rar|7z|zip|mod|sum|iso|patch|json|css|scss|sass))\s?'
)

RE_URL_OR_PATH = RE_COMMON_FILENAME + "|" + RE_PATH + "|" + RE_URL


def mark(text, args, Mark, extra_cli_args, *a):
    for idx, m in enumerate(re.finditer(RE_URL_OR_PATH, text)):
        start, end = m.span()
        mark_text = text[start:end].replace('\n', '').replace('\0', '').strip()
        yield Mark(idx, start, end, mark_text, {})


def handle_result(args, data, target_window_id, boss, extra_cli_args, *a):
    matches, groupdicts = [], []
    for m, g in zip(data['match'], data['groupdicts']):
        if m:
            matches.append(m)
            groupdicts.append(g)
    for word, match_data in zip(matches, groupdicts):
        set_clipboard_string(word)
