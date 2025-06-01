local M = {}

function M.create_term(opts)
    local buf_exists = opts.buf
    opts.buf = opts.buf or vim.api.nvim_create_buf(false, true) -- false, true - this buffer is not listed in the buffer list, and it is a scratch buffer, meaning you can discard the text within easily
end


function M.term_cmd(opts)
    if opts.cmd == nil then
        opts.cmd = "echo 'ERROR: no cmd passed!'"
    end
    -- We need to create the buffer, then send the keys over, those keys being "clear; <cmd>"
end

M.term_cmd{cmd = "echo 'nuts'"}

-- [[ 
-- TODO: Add terminal functionality using the built in API.
--       NvChad uses vim.fn.termopen, which seemed promising, but there doesn't seem to be any documentation on it.
-- ]]
-- Splits on spaces or slashes, depending on delim, if you call without delim, the default will be spaces
function M.split(str, delim)
    local pat = "%S+"
    if delim == "slash" then
        pat = "[^/]"
    end
    local arr = {}
    for i in string.gmatch(str, pat) do
        table.insert(arr, i)
    end
    return arr
end

return M
