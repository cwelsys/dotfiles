local wez = require("wezterm")

local M = {}

-- M.set_status = function()
-- end

M.set_status = function()
    local function tab_title(tab_info)
        local title = tab_info.tab_title
        -- if the tab title is explicitly set, take that
        if title and #title > 0 then
            return title
        end
        -- Otherwise, use the title from the active pane
        -- in that tab
        return "untitled"
    end

    wez.on("format-tab-title", function(tab, tabs, panes, config, hover, max_width)
        local title = tab_title(tab)

        local index_background
        local index_foreground
        local title_background
        local title_foreground
        local edge_background = "#1e1e2e" -- Mocha base

        if tab.is_active then
            index_background = "#cba6f7" -- Mauve
            index_foreground = "#1e1e2e" -- Base
            title_background = "#f5c2e7" -- Pink
            title_foreground = "#1e1e2e" -- Base
        else
            index_background = "#6c7086" -- Overlay0
            index_foreground = "#cdd6f4" -- Text
            title_background = "#45475a" -- Surface1
            title_foreground = "#cdd6f4" -- Text
        end

        return {
            "ResetAttributes",
            { Background = { Color = index_background } },
            { Foreground = { Color = index_foreground } },
            { Text = " " .. (tab.tab_index + 1) .. " " },
            { Background = { Color = title_background } },
            { Foreground = { Color = title_foreground } },
            -- { Text = " " .. wez.truncate_right(title, max_width - 5) .. " " },
            { Text = " " .. title .. " " },
            "ResetAttributes",
            { Background = { Color = edge_background } },
            { Text = " " },
            "ResetAttributes",
        }
        -- return " " .. (tab.tab_index + 1) .. " " .. title .. " "
    end)

    wez.on("update-right-status", function(window, pane)
        -- Each element holds the text for a cell in a "powerline" style << fade
        local cells = {}

        -- Figure out the cwd and host of the current pane.
        -- This will pick up the hostname for the remote host if your
        -- shell is using OSC 7 on the remote host.
        local cwd_uri = pane:get_current_working_dir()
        if cwd_uri then
            local cwd = ""
            local hostname = ""

            if type(cwd_uri) == "userdata" then
                -- Running on a newer version of wez and we have
                -- a URL object here, making this simple!
                cwd = cwd_uri.file_path
                hostname = cwd_uri.host or wez.hostname()
            end

            -- Remove the domain name portion of the hostname
            local dot = hostname:find("[.]")
            if dot then
                hostname = hostname:sub(1, dot - 1)
            end
            if hostname == "" then
                hostname = wez.hostname()
            end

            -- table.insert(cells, cwd)
            table.insert(cells, hostname)
        end

        table.insert(cells, window:active_workspace())
        table.insert(cells, string.format("Domain: %s", pane:get_domain_name()))
        local mux_id = window:mux_window()
        if mux_id ~= nil then
            table.insert(cells, string.format("Mux: %s", mux_id:window_id()))
        end

        -- I like my date/time in this style: "Wed Mar 3 08:14"
        -- local date = wez.strftime("%a %b %-d %H:%M")
        -- table.insert(cells, date)

        -- An entry for each battery (typically 0 or 1 battery)
        -- for _, b in ipairs(wez.battery_info()) do
        --     table.insert(cells, string.format("%.0f%%", b.state_of_charge * 100))
        -- end

        -- The powerline < symbol
        local LEFT_ARROW = utf8.char(0xe0b3)
        -- The filled in variant of the < symbol
        local SOLID_LEFT_ARROW = utf8.char(0xe0b2)

        -- Color palette for the backgrounds of each cell
        local colors = {
            "#cba6f7", -- Mauve
            "#f38ba8", -- Red
            "#fab387", -- Peach
            "#f9e2af", -- Yellow
            "#a6e3a1", -- Green
        }

        -- Foreground color for the text across the fade
        local text_fg = "#1e1e2e" -- Base

        -- The elements to be formatted
        local elements = {}
        -- How many cells have been formatted
        local num_cells = 0

        -- Translate a cell into elements
        function push(text, is_last)
            local cell_no = num_cells + 1
            table.insert(elements, { Foreground = { Color = text_fg } })
            table.insert(elements, { Background = { Color = colors[cell_no] } })
            table.insert(elements, { Text = " " .. text .. " " })
            if not is_last then
                table.insert(elements, { Foreground = { Color = colors[cell_no + 1] } })
                table.insert(elements, { Text = SOLID_LEFT_ARROW })
            end
            num_cells = num_cells + 1
        end

        while #cells > 0 do
            local cell = table.remove(cells, 1)
            push(cell, #cells == 0)
        end

        window:set_right_status(wez.format(elements))
    end)

    wez.on("update-status", function(window, pane)
        local date = wez.strftime("%H:%M:%S")

        local mode_status = {}

        local key_table = window:active_key_table()

        if key_table == "resize" then
            mode_status = {
                { Attribute = { Intensity = "Bold" } },
                { Foreground = { Color = "#1e1e2e" } }, -- Base
                { Background = { Color = "#f5e0dc" } }, -- Rosewater
                { Text = " " .. "RES" .. " " },
                "ResetAttributes",
                { Text = " " },
            }
        elseif window:leader_is_active() then
            mode_status = {
                -- { Attribute = { Intensity = "Bold" } },
                -- { Foreground = { Color = "#1e1e2e" } }, -- Base
                { Background = { Color = "#f2cdcd" } }, -- Flamingo
                { Text = " " .. "" .. " " },
                "ResetAttributes",
                { Text = " " },
            }
        else
            mode_status = {
                { Attribute = { Intensity = "Bold" } },
                { Foreground = { Color = "#1e1e2e" } }, -- Base
                { Background = { Color = "#b4befe" } }, -- Lavender
                { Text = " " .. "NOR" .. " " },
                "ResetAttributes",
                { Text = " " },
            }
        end

        window:set_left_status(wez.format(mode_status))
    end)
end

return M
