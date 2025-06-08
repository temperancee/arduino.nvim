local util = require "arduino.util"

-- TODO: These should be ran as coroutines in the background so we don't have the 3-4 second delay when refreshing them

local M = {}

---@return table board_tbl #An array of tuples containing the board names and FQBNs
--- Reloads the board list
function M.refresh_board_list()
    local board_file = io.popen("arduino-cli board listall")
    if board_file == nil then
        vim.print("ERROR: Board list is nil - have you installed your arduino-cli cores?")
        return nil
    end
    local board_tbl = {}
    board_file:read() -- read and discard the first row, which contains the headers
    for line in board_file:lines() do
        local splt = util.split(line, " ")
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
function M.refresh_port_list()
    local port_file, err = io.popen("arduino-cli board list --json | jq -r .detected_ports[].port.label")
    if port_file == nil then
        vim.print("Failed to read arduino-cli board list, ERROR: "..err)
    end
    local port_tbl = {}
    for line in port_file:lines() do
        table.insert(port_tbl, line)
    end
    port_file:close()
    return port_tbl
end

return M
