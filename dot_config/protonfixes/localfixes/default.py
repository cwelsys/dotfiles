import hashlib
import subprocess
from importlib import import_module
from pathlib import Path
from types import ModuleType
from typing import Optional

from protonfixes import fix, util
from protonfixes.logger import log

REG = Path(__file__).resolve().parent.parent / 'defaults.reg'


def _shipped(game_id: str) -> Optional[ModuleType]:
    try:
        return import_module(fix.get_module_name(game_id, default=True))
    except ImportError:
        return None


def early_with_id(game_id: str) -> None:
    shipped = _shipped(game_id)
    if hasattr(shipped, 'early_with_id'):
        shipped.early_with_id(game_id)
    elif hasattr(shipped, 'early'):
        shipped.early()


def main_with_id(game_id: str) -> None:
    shipped = _shipped(game_id)
    if hasattr(shipped, 'main_with_id'):
        shipped.main_with_id(game_id)
    elif hasattr(shipped, 'main'):
        shipped.main()

    try:
        _apply_defaults()
    except Exception as e:
        log.warn(f'defaults.reg not applied: {e}')


def _apply_defaults() -> None:
    pfx = util.protonprefix()
    version = pfx.parent / 'version'
    stamp = pfx / '.defaults-applied'
    want = hashlib.sha256(
        REG.read_bytes() + (version.read_bytes() if version.exists() else b'')
    ).hexdigest()
    if stamp.exists() and stamp.read_text() == want:
        return

    env = dict(util.protonmain.g_session.env)
    env['WINEPREFIX'] = str(pfx)
    reg = 'Z:' + str(REG).replace('/', '\\')
    done = subprocess.run(
        [util.protonmain.g_proton.wine_bin, 'regedit', '/S', reg], env=env, check=False
    )
    if done.returncode != 0:
        log.warn(f'defaults.reg: regedit exited {done.returncode}')
        return
    stamp.write_text(want)
    log.info(f'defaults.reg applied to {pfx}')
