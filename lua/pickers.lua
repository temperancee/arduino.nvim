-- Include telescope
local pickers = require "telescope.pickers"
local finders = require "telescope.finders"
local conf = require("telescope.config").values
local actions = require "telescope.actions"
local action_state = require "telescope.actions.state"

-- Include modules
local misc_util = require "util.misc_util"
local config_util = require "util.config_util"

-- State variables
---@type table?
Board_Tbl = {}
---@type string[]?
Port_Tbl = {}


local M = {}


-- TODO: These should be ran as coroutines in the background so we don't have the 3-4 second delay when refreshing them
---@return table? board_tbl #An array of tuples containing the board names and FQBNs
--- Reloads the board list
local function refresh_board_list()
    local board_file = io.popen("arduino-cli board listall")
    if board_file == nil then
        vim.print("ERROR: Board list is nil - have you installed your arduino-cli cores?")
        return nil
    end
    local board_tbl = {}
    board_file:read() -- read and discard the first row, which contains the headers
    for line in board_file:lines() do
        local splt = misc_util.split(line, " ")
        -- The final word on each line is always the FQBN, then the rest of the words are the board name, so we inset the FQBN to our csv line first, then add the rest of the words as board name
        local len = #splt
        local line_arr = {splt[len]}
        table.remove(splt, len)
        table.insert(line_arr, 1, table.concat(splt, " "))
        table.insert(board_tbl, line_arr)
    end
    board_file:close()
    return board_tbl
end


---@return string[]? port_tbl #An array containing all port names
--- Gets a list of ports - unlike boards, we make use of the json output (the board listall json is wayyyy too long - I only have 2 core libs and it's over 21000 lines long - this json is way shorter), which is filtered using jq to provide the list of ports
local function refresh_port_list()
    local port_file, err = io.popen("arduino-cli board list --json | jq -r .detected_ports[].port.label")
    if port_file == nil then
        vim.print("Failed to read arduino-cli board list, ERROR: "..err)
        return nil
    end
    local port_tbl = {}
    for line in port_file:lines() do
        table.insert(port_tbl, line)
    end
    port_file:close()
    return port_tbl
end


---@param info {type: string, value: any, display: string, ordinal: string } #a list containing info on whether this is port or core details, and the details of the core/port
---@return number? #0 for success, nil for error
--- The general idea here is we read the whole config file into a table, then edit the necessary line, then write the whole file back
local function edit_config(info)
    local current_file_path = vim.api.nvim_buf_get_name(0)
    local config_f = config_util.get_config_file(current_file_path)
    -- propagate possible nil from get_config_file due to no .ino file through the system
    if config_f == nil then
        return nil
    end
    local contents = config_util.read_config(config_f)
    -- propagate errros, could be either due to no .ino file or no sketch.yaml file
    if contents == nil then
        return nil
    end
    -- Edit core/port field
    if info.type == "board" then
        contents["fqbn"] = info.value[2]
    elseif info.type == "port" then
        contents["port"] = info.value
    end
    -- Write config back
    local file = io.open(config_f, "w")
    local str_contents = "default_fqbn: "..contents["fqbn"].."\ndefault_port: "..contents["port"]
    if file == nil then
        vim.print("ERROR: Opening sketch.yaml file failed")
        return nil
    end
    local success, err = file:write(str_contents)
    io.close(file)
    if success == nil then
        vim.print("Writing to sketch.yaml failed, ERROR: "..err)
        return nil
    end
    return 0
end

--[[ TODO:
     Call lists.refresh_board_list on startup of a .ino file
     Bind the commands and figure out how to check the existing one isn't busy ("terminal is busy, please wait until compilation/uploading is finished", don't ask them if they want to open a new terminal, I doubt anyone will need to compile/upload multiple programs at one)
     Test to see what it currently does when you spam compile three times
--]]

-- [[ NOTE:
--    We load the board/port list into a table in the background (probably using a coroutine) each time we open an arduino file
-- ]]

-- the board picker function
M.board = function(opts)
    opts = opts or {}
    pickers.new(opts, {
        prompt_title = "Select board",
        finder = finders.new_table {
            results = Board_Tbl, -- comes from lists.refresh_board_list, which is called on startup
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
                edit_config(selection)
            end
          end)
          return true
        end,
    }):find()
end

-- gets a list of ports - unlike cores, we just reload this every time, because it changes more often
M.port = function(opts)
    opts = opts or {}
    pickers.new(opts, {
        prompt_title = "Select port",
        finder = finders.new_table {
            results = Port_Tbl,
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
                edit_config(selection)
            end
          end)
          return true
        end,
    }):find()
end

--- Refreshes board and port lists for pickers
function M.refresh_lists()
    Board_Tbl = refresh_board_list()
    Port_Tbl = refresh_port_list()
end

-- Refresh lists on first run
M.refresh_lists()

return M
