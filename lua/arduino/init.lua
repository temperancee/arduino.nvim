local pickers = require "telescope.pickers"
local finders = require "telescope.finders"
local conf = require("telescope.config").values
local actions = require "telescope.actions"
local action_state = require "telescope.actions.state"

-- Include modules
local commands = require "arduino.commands"
local lists    = require "arduino.lists"

-- consts
local board_tbl = {}
---@type string[]?
local port_tbl = {}



--[[ TODO:
     Call lists.refresh_board_list on startup of a .ino file
     Bind the commands and figure out how to check the existing one isn't busy ("terminal is busy, please wait until compilation/uploading is finished", don't ask them if they want to open a new terminal, I doubt anyone will need to compile/upload multiple programs at one)
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
            if selection ~= nil then
                selection["type"] = "board"
                commands.edit_config(selection)
            end
          end)
          return true
        end,
    }):find()
end

-- gets a list of ports - unlike cores, we just reload this every time, because it changes more often
local port = function(opts)
    opts = opts or {}
    pickers.new(opts, {
        prompt_title = "Select port",
        finder = finders.new_table {
            results = port_tbl,
            entry_maker = function(entry)
                return {
                    value = entry,
                    display = entry,
                    ordinal = entry
                }
            end
        },
        sorter = conf.generic_sorter(opts),

        -- replace board picker actions
        attach_mappings = function(prompt_bufnr, map)
          actions.select_default:replace(function()
            actions.close(prompt_bufnr)
            local selection = action_state.get_selected_entry()
            if selection ~= nil then
                selection["type"] = "port" -- this is coming from the port function
                commands.edit_config(selection)
            end
          end)
          return true
        end,
    }):find()
end



-- TODO: Have this plugin loaded only when a .ino file is opened (can we unload it afterwards?)

board_tbl = lists.refresh_board_list()
if board_tbl == nil then
    board_tbl = {} -- reset if there is an error
end
port_tbl = lists.refresh_port_list()
if port_tbl == nil then
    port_tbl = {} -- reset if there is an error
end
-- TODO: these keymaps should probably be elsewhere (certainly in their own file)
vim.keymap.set("n", "<leader>ab", board, { desc = "Arduino board picker" })
vim.keymap.set("n", "<leader>ap", port, { desc = "Arduino port picker" })
vim.keymap.set("n", "<leader>ac", function() commands.compile() end, { desc = "Arduino compile sketch" })
vim.keymap.set("n", "<leader>au", function () commands.upload() end, { desc = "Arduino upload sketch" })
vim.keymap.set("n", "<leader>ar", function ()
    lists.refresh_board_list()
    lists.refresh_port_list()
end, { desc = "Arduino refresh picker lists" })
vim.keymap.set("n", "<leader>an", function () commands.create_file() end, { desc = "Arduino create new sketch" })
vim.keymap.set("n", "<leader>ag", function () commands.create_current_config_file() end, { desc = "Arduino create config file for current sketch" })


