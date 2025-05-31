local M = {}

-- Splits on spaces or slashes, depending on delim, if you call without delim, the default will be spaces
function M.split(str, delim)
    local pat = "%S+"
    if delim == "slash" then
        pat = "[^/]"
    end
    arr = {}
    for i in string.gmatch(str, delim) do
        table.insert(arr, i)
    end
    return arr
end

return M
