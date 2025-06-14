
local M = {}

-- Splits on spaces or slashes, depending on delim, if you call without delim, the default will be spaces
function M.split(str, delim)
    local pat = "[^%"..delim.."]+"
    if delim == " " then
        pat = "%S+"
    end
    local arr = {}
    for i in string.gmatch(str, pat) do
        table.insert(arr, i)
    end
    return arr
end

return M
