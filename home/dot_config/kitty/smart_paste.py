#!/usr/bin/env python3
def main(args):
    pass


from kittens.tui.handler import result_handler


def get_clipboard() -> str:
    import shutil
    import subprocess

    if shutil.which("pbpaste"):
        return subprocess.run(["pbpaste"], capture_output=True, text=True).stdout
    if shutil.which("wl-paste"):
        return subprocess.run(["wl-paste"], capture_output=True, text=True).stdout
    if shutil.which("xclip"):
        return subprocess.run(
            ["xclip", "-selection", "clipboard", "-o"], capture_output=True, text=True
        ).stdout
    if shutil.which("xsel"):
        return subprocess.run(
            ["xsel", "--clipboard", "--output"], capture_output=True, text=True
        ).stdout
    return ""


@result_handler(no_ui=True)
def handle_result(args, answer, target_window_id, boss):
    text = get_clipboard()

    lines = text.strip().split("\n")
    if len(lines) > 1 and all(line.startswith((" ", "\t")) for line in lines[1:]):
        text = " ".join(line.strip() for line in lines)

    w = boss.window_id_map.get(target_window_id)
    if w is not None:
        w.paste_text(text)
