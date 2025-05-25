local pickers = require "telescope.pickers"
local finders = require "telescope.finders"
local conf = require("telescope.config").values
local actions = require "telescope.actions"
local action_state = require "telescope.actions.state"

-- consts
local config_file = "lua/arduino/config"
local board_tbl = {}

-- Include modules
local commands = require "arduino.commands"
local lists    = require "arduino.lists"


--[[ TODO:
     Call lists.refresh_board_list on startup of a .ino file
     Bind the commands and figure out how to check if we need to spawn a terminal, and how to check the existing one isn't busy ("terminal is busy, would you like to open a new one?")
--]]

-- [[ NOTE:
--    We load the board/port list into a table in the background (probably using a coroutine) each time we open an arduino file
--    We will also provide a command to reload the tables 
-- ]]

-- the board picker function
local board = function(opts)
    opts = opts or {}
    pickers.new(opts, {
        prompt_title = "Select board",
        finder = finders.new_table {
            results = board_tbl, -- comes from lists.refresh_board_list, which is called on startup
             entry_maker = function(entry)
                return {
                    value = entry,
                    display = entry[1],
                    ordinal = entry[1] -- 1 is the board name
                }
            end
        },
        sorter = conf.generic_sorter(opts),

        -- replace board picker actions
        attach_mappings = function(prompt_bufnr, map)
          actions.select_default:replace(function()
            actions.close(prompt_bufnr)
            local selection = action_state.get_selected_entry()
            selection["type"] = "board" -- this is coming from the board function, if coming from port function, this will be port
            commands.edit_config(selection, config_file)
            -- commands.test(config_file)
            -- vim.print(selection)
          end)
          return true
        end,
    }):find()
end

-- TODO: change the stuff in here to be for port
local port = function(opts)
    opts = opts or {}
    pickers.new(opts, {
        prompt_title = "Select port",
        finder = finders.new_table {
            results = lists.gen_core_entries(core_file),
            entry_maker = function(entry)
                return {
                    value = entry,
                    display = entry[4],
                    ordinal = entry[4]
                }
            end
        },
        sorter = conf.generic_sorter(opts),

        -- replace board picker actions
        attach_mappings = function(prompt_bufnr, map)
          actions.select_default:replace(function()
            actions.close(prompt_bufnr)
            local selection = action_state.get_selected_entry()
            selection["type"] = "core" -- this is coming from the core function, if coming from port function, this will be port
            commands.edit_config(selection, config_file)
            -- commands.test(config_file)
            -- vim.print(selection)
          end)
          return true
        end,
    }):find()
end

-- NOTE:  we call refresh_board_list() at on startup, then have this plugin loaded only when a .ino file is opened (can we unload it afterwards though?)

board_tbl = lists.refresh_board_list()
vim.keymap.set("n", "<leader>ab", board, { desc = "Arduino board picker" })
