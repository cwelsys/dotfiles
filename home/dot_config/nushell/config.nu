source ./themes/catppuccin_mocha.nu
overlay use ./scripts/git-aliases.nu

$env.config.plugins.highlight.theme = "ansi"
$env.config.buffer_editor = "nvim"
$env.config.show_banner = false
$env.config.edit_mode = 'vi'
$env.config.menus = [
      {
        name: completion_menu
        only_buffer_difference: false # Search is done on the text written after activating the menu
        marker: "⎁ "                  # Indicator that appears with the menu is active
        type: {
            layout: columnar          # Type of menu
            columns: 4                # Number of columns where the options are displayed
            col_width: 20             # Optional value. If missing all the screen width is used to calculate column width
            col_padding: 2            # Padding between columns
        }
        style: {
            text: green                   # Text style
            selected_text: green_reverse  # Text style for selected option
            description_text: yellow      # Text style for description
        }
      },
      {
        name: history_menu
        only_buffer_difference: false # Search is done on the text written after activating the menu
        marker: "⌂ "                 # Indicator that appears with the menu is active
        type: {
            layout: list             # Type of menu
            page_size: 10            # Number of entries that will presented when activating the menu
        }
        style: {
            text: green                   # Text style
            selected_text: green_reverse  # Text style for selected option
            description_text: yellow      # Text style for description
        }
      }
]
$env.config.completions.algorithm = "fuzzy"
$env.config.keybindings = [
    {
      name: change_dir_with_fzf
      modifier: control
      keycode: char_f
      mode: [ emacs, vi_normal, vi_insert ],
      event: {
        send: executehostcommand,
        cmd: "F"
      }
    },
    {
    name: fuzzy_history_fzf
    modifier: control
    keycode: char_r
    mode: [emacs , vi_normal, vi_insert]
    event: {
      send: executehostcommand
      cmd: "commandline edit --replace (
        history
          | get command
          | reverse
          | uniq
          | str join (char -i 0)
          | fzf --scheme=history --read0 --tiebreak=chunk --layout=reverse --preview='echo {..}' --preview-window='bottom:3:wrap' --bind alt-up:preview-up,alt-down:preview-down --height=70% -q (commandline) --preview='echo -n {} | nu --stdin -c \'nu-highlight\''
          | decode utf-8
          | str trim
      )"
    }
  }
]

def F --env () {
    let result = fd --color=always | fzf --ansi --preview='nu ~/.config/nushell/scripts/preview.nu {}'
    if ($result | path type) == "dir" {
        cd $result
    } else if ($result != "") {
        linkhandler $result
    }
}

def D --env () {
    let result = fd -t d --color=always | fzf --ansi --preview='nu ~/.config/nushell/scripts/preview.nu {}'
    if $result != "" {
        cd $result
    }
}

def E --env () {
    let result = fd --color=always | fzf --ansi --preview='nu ~/.config/nushell/scripts/preview.nu {}'
    if ($result | path type) == "dir" {
        cd $result
    } else if ($result != "") {
        $env.TARGET = "edit"
        linkhandler $result
        hide-env TARGET
    }
}

source ~/.cache/carapace/init.nu
source ~/.local/share/atuin/init.nu

plugin use highlight

source ($nu.default-config-dir | path join mise.nu)

source ~/.cache/.aliae.nu
source ~/.cache/.zoxide.nu

