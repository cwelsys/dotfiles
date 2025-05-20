<h1 align=center>
  cwel DOTFILES
</h1>

<div align=center>
  <a href="../../commits/main">
    <img alt="Last commit" src="https://img.shields.io/github/last-commit/cwelsys/dotfiles?style=for-the-badge&color=f2cdcd&labelColor=363a4f"/>
  </a>
  <img alt="Repo size" src="https://img.shields.io/github/repo-size/cwelsys/dotfiles?style=for-the-badge&color=eba0ac&labelColor=363a4f"/>
  <a href="https://www.chezmoi.io/">
    <img alt="Chezmoi" src="https://img.shields.io/badge/chezmoi-fab387?style=for-the-badge"/>
  </a>
  <a href="https://github.com/HyDE-Project/HyDE">
    <img alt="HyDE" src="https://img.shields.io/badge/Hyde-cba6f7?style=for-the-badge"/>
  </a>
</div>

<div align=center>
  <img alt="Arch" src="https://img.shields.io/badge/Arch-89b4fa?logo=arch-linux&logoColor=white&style=for-the-badge"/>
  <img alt="EndeavourOS" src="https://img.shields.io/badge/endeavour%20os-b4befe?logo=endeavouros&logoColor=white&style=for-the-badge"/>
  <img alt="Windows" src="https://img.shields.io/badge/Windows-74c7ec?style=for-the-badge&logo=windows&logoColor=white"/>
</div>

<div align="center">
  <img src="https://raw.githubusercontent.com/catppuccin/catppuccin/main/assets/palette/macchiato.png" width="400" />
</div>

---

## ToC

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [😎 Showcase](#-showcase)
  - [Terminal](#terminal)
  - [Neovim](#neovim)
- [⚙️ Installation](#-installation)
- [📝 Other notes](#-other-notes)
- [💁 References](#-references)
  - [Wallpaper](#wallpaper)
  - [Other dotfiles](#other-dotfiles)
    - [Preconfig](#preconfig)
    - [Chezmoi](#chezmoi)
    - [Others](#others)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

---

## 😎 Showcase

### Terminal

| **Linux**                                             | **Windows**                                               |
| ----------------------------------------------------- | --------------------------------------------------------- |
| ![Linux terminal](./assets/images/linux/terminal.png) | ![Windows terminal](./assets/images/windows/terminal.png) |

### Neovim

| **Linux**                                         | **Windows**                                           |
| ------------------------------------------------- | ----------------------------------------------------- |
| ![Linux Neovim](./assets/images/linux/neovim.png) | ![Windows Neovim](./assets/images/windows/neovim.png) |

> [!NOTE]
> Neovim config <https://github.com/cwelsys/nvim>

---

## ⚙️ Installation

- Add ssh key
  - Linux
    ```sh
    eval "$(ssh-agent -s)"
    chmod 700 ~/.ssh/
    chmod 644 ~/.ssh/id_ed25519.pub
    chmod 600 ~/.ssh/id_ed25519
    ssh-add ~/.ssh/id_ed25519
    ```
  - Windows
    ```powershell
    Set-Service ssh-agent -StartupType Automatic
    Start-Service ssh-agent
    Ssh-Add "$env:USERPROFILE/.ssh/id_ed25519"
    ```
- Create `~/.age-key.txt` _(for encrypt/decrypt)_

  > This is for personal use, as it contains encrypted files. If you wish to use it, run chezmoi apply with the `--exclude=encrypted` argument

- Install chezmoi and init, apply, and delete binary: _([docs](https://www.chezmoi.io/install))_
  - shell
    ```sh
    sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply --ssh --depth 1 --purge-binary cwelsys
    ```
  - pwsh
    ```powershell
    iex "&{$(irm 'https://get.chezmoi.io/ps1')} -- init --apply --ssh --depth 1 --purge-binary cwelsys"
    ```
- GPG for sign commit
  ```sh
  gpg --import public.gpg
  gpg --import secret.gpg
  gpg --edit-key cwelsys
  trust
  5
  y
  quit
  ```
  > On windows use GPG from git. We can open `git bash`

---

## 📝 Other notes

- [Windows](./docs/windows.md)
- [Linux](./docs/linux.md)
- [Browser](./docs/browser.md)
- [Terminal](./docs/terminal.md)

---

## 💁 References

### Wallpaper

- <https://github.com/D3Ext/aesthetic-wallpapers>
- <https://github.com/DenverCoder1/minimalistic-wallpaper-collection>
- <https://github.com/Gingeh/wallpapers>

### Other dotfiles

#### Preconfig

- <https://github.com/JaKooLit/Hyprland-Dots>
- <https://github.com/end-4/dots-hyprland>
- <https://github.com/gh0stzk/dotfiles> (BSPWM)
- <https://github.com/koeqaife/hyprland-material-you>
- <https://github.com/prasanthrangan/hyprdots>
- <https://gitlab.com/stephan-raabe/dotfiles>

#### Chezmoi

- <https://github.com/megabyte-labs/install.doctor>
- <https://github.com/lildude/dotfiles/> (Have config for codespace)

#### Others

- <https://github.com/2KAbhishek/dots2k>
- <https://github.com/2nthony/dotfiles> (Lazygit?)
- <https://github.com/Alexis12119/dotfiles>
- <https://github.com/Cybersnake223/Hypr>
- <https://github.com/Integralist/dotfiles>
- <https://github.com/JoosepAlviste/dotfiles>
- <https://github.com/amitds1997/dotfiles> (setup for arch and mac, git stuff, something is new to me)
- <https://github.com/asilvadesigns/config>
- <https://github.com/bahamas10/dotfiles> (YSAP)
- <https://github.com/chaneyzorn/dotfiles>
- <https://github.com/craftzdog/dotfiles-public>
- <https://github.com/dlvhdr/dotfiles>
- <https://github.com/dreamsofautonomy/zensh>
- <https://github.com/linkarzu/dotfiles-latest>
- <https://github.com/mischavandenburg/dotfiles>
- <https://github.com/nguyenvukhang/docker-dev>
- <https://github.com/nguyenvukhang/dots> (git config!)
- <https://github.com/omerxx/dotfiles> (have good tmux plugins)
- <https://github.com/p3nguin-kun/dotfiles>
- <https://github.com/petobens/dotfiles> (X config, tmux for linux & mac)
- <https://github.com/rusty-electron/dotfiles>
- <https://github.com/siduck/dotfiles>
- <https://github.com/stevearc/dotfiles>
- <https://github.com/wincent/wincent> (Old dotfiles 😱)
