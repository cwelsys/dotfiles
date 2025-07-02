function y --description "yazi fish shell wrapper"
	set tmp (mktemp -t "yazi-cwd.XXXXXX")
	yazi $argv --cwd-file="$tmp"
	if set cwd (command cat -- "$tmp"); and [ -n "$cwd" ]; and [ "$cwd" != "$PWD" ]
		builtin cd -- "$cwd"
	end
	rm -f -- "$tmp"
end

function mkcd -d "Create a directory and set CWD"
    command mkdir $argv
    if test $status = 0
        switch $argv[(count $argv)]
            case '-*'

            case '*'
                cd $argv[(count $argv)]
                return
        end
    end
end
function cdl -d "List contents of a directory after changing to it"
    cd $argv && ls -la
end

function brews
    set formulae "$(brew leaves | xargs brew deps --installed --for-each)"
    set casks "$(brew list --cask)"

    echo \=\=\> (set_color --bold red)Formulae
    echo (set_color normal)$formulae | sed "s/^\(.*\):\(.*\)\$/\1$(set_color blue)\2$(set_color normal)/"
    echo \n\=\=\> (set_color --bold red)Casks
    echo (set_color normal)$casks
end

