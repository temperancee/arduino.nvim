
local M = {}


-- Splits on spaces
local split = function(str)
    arr = {}
    for i in string.gmatch(str, "%S+") do
        table.insert(arr, i)
    end
    return arr
end

-- This will read in the core list json, filter it, and whack it in the core file for gen_core_entries to read. Using a core file means that we don't have to call the core list command (v slow) every time we open the telescope dialogue
-- HACK: Outsourcing this processing to jq seems silly at first, but lua doesn't seem to be able to handle it (I tried pulling in the json core list using json.lua, and my nvim hung). My only issue with this is that it isn't just contained in a jq script, and that we have to have this weird back and forth where lua handles the loop logic and jq does the lifting.
-- Also having to remove the files at the end sucks - having to use them at all sucks.
-- NOTE: I'm changing this to use `arduino board listall` instead, which filters down the json output (which has thousands of repeated lines). This makes filtering a bit harder, but is worth it in processing time
--
--
-- function M.refresh_core_list(core_file)
--     -- get rid of the old file
--     os.execute("rm "..core_file)
--     -- store core list output so we don't have to run the v slow command during subsequent queries
--     os.execute("arduino-cli core list --json >> "..core_json_list)
--     -- get the list of installed versions of the cores
--     local ins_vers_f = io.popen("cat "..core_json_list.." | jq '.platforms[].installed_version'")
--     -- loop through each one, and as we do, use it to filter the json list, providing us with all the up to date board info for that core
--     vers_tbl = {}
--     boards_str = ""
--     local i = 1
--     for i,line in io.lines() do
--         os.execute("cat "..core_json_list.." | jq '.platforms["..tostring(i-1).."].releases["..line.."].boards' >> board"..i..".json")
--         boards_str = boards_str.."board"..i..".json "
--         i = i + 1
--     end
--     os.execute("jq -n '{ board: [inputs] | add }' "..boards_str..">> "..core_file) -- no space after boards_str because there is already one on the end
--     -- remove temporary files
--     os.execute("rm "..boards_str.." "..core_json_list)
-- end
--

-- @returns board_tbl - a table containing the board names and FQBNs
function M.refresh_board_list()
    board_file = io.popen("arduino-cli board listall")
    board_tbl = {}
    io.input(board_file) -- point input to the board list file
    io.read() -- read the first row, which contains the headers
    for line in io.lines() do
        local splt = split(line)
        -- The final word on each line is always the FQBN, then the rest of the words are the board name, so we inset the FQBN to our csv line first, then add the rest of the words as board name
        local line_arr = {splt[-1]}
        table.remove(splt, -1)
        table.insert(line_arr, 1, table.concat(splt, " "))
        table.insert(tbl, line_arr)
    end
    return board_tbl
end


-- gets a list of ports - unlike cores, we just reload this every time, because it changes more often
function M.gen_port_entries(port_file)
    os.execute("rm "..port_file)
    os.execute("arduino-cli board list >> "..port_file)
    tbl = {}
    io.input(port_file)
    io.read() -- remove first row, contains headers
    for line in io.lines() do
        local splt = split(line)
        table.insert(tbl, splt[1]) -- we only care about the port, which is the first entry
    end
    return tbl
end

return M

