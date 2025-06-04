# github.com/cwelsys/dotfiles

Connor's dotfiles, managed with [`chezmoi`](https://github.com/twpayne/chezmoi).

Install them with:

```console
$ chezmoi init cwelsys
```

Personal secrets are stored in [1Password](https://1password.com) and you'll
need the [1Password CLI](https://developer.1password.com/docs/cli/) installed.
Login to 1Password with:

```console
$ eval $(op signin)
```

> This is for personal use, as it contains encrypted files. If for some reason you wish to proceed anyways, run chezmoi apply with `--exclude=encrypted`
