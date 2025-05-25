
local M = {}


-- Splits on spaces
local split = function(str)
    arr = {}
    for i in string.gmatch(str, "%S+") do
        table.insert(arr, i)
    end
    return arr
end


-- @returns board_tbl - a table containing the board names and FQBNs
function M.refresh_board_list()
    board_file = io.popen("arduino-cli board listall")
    board_tbl = {}
    board_file:read() -- read the first row, which contains the headers
    for line in board_file:lines() do
        local splt = split(line)
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


-- gets a list of ports - unlike boards, we make use of the json output (the board listall json is wayyyy too long - I only have 2 core libs and it's over 21000 lines long - this json is way shorter), which is filtered using jq to provide the list of ports
function M.refresh_port_list()
    port_file = io.popen("arduino-cli board list --json | jq -r .detected_ports[].port.label")
    tbl = {}
    for line in port_file:lines() do
        table.insert(tbl, line) 
    end
    port_file:close()
    return tbl
end

return M

