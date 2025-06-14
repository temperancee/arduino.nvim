
local M = {}

term_ids = {} -- A dictionary connecting terminal IDs (passed into create_term) linked to buffer and channel IDs

-- TODO: Add an option to not open a shell within the terminal, like in the Arduino IDE

---@param opts {id: string, cmd: string}
local function create_term(opts)
        local shell = vim.o.shell
        local buf = vim.api.nvim_create_buf(false, true) -- false, true - this buffer is not listed in the buffer list, and it is a scratch buffer, meaning you can discard the text within easily
        vim.api.nvim_open_win(buf, true, {
            split = 'below',
            win = 0,
            height = 14
        })
        -- Run the cmd in the terminal, collecting the channel ID for later use
        local chan = vim.fn.jobstart({"bash", "-c", opts.cmd .. "; ".. shell}, {term=true})
        term_ids[opts.id] = {buf=buf, chan=chan}
end

function M.runner_term(opts)
    if opts.id == nil then
        print("ERROR: No ID passed")
    end
    opts.cmd = opts.cmd or ":" -- : is the "do nothing command", so if no cmd is passed, a terminal will just open without running anything
    -- Get the buffer and channel ids linked to this id, if there are any - this allows us to us a pre-existing terminal
    local ids = term_ids[opts.id] or nil
    -- If there is no buffer with this ID, create a new one and open it
    if ids == nil then
        create_term(opts)
    else
        -- We now need to check whether there is a buffer linked to this opts.id, and if there isn't we create a new term as above
        if ids.buf == nil then
            create_term(opts)
        else
            -- Send the cmd to that terminal buffer using its channel id
            vim.api.nvim_chan_send(ids.chan, opts.cmd .. " \n")
        end
    end
end

return M
