


local M = {}

local function create_term(opts)
    local buf_exists = opts.buf
    opts.buf = opts.buf or vim.api.nvim_create_buf(false, true) -- false, true - this buffer is not listed in the buffer list, and it is a scratch buffer, meaning you can discard the text within easily
end


function term_cmd(opts)
    if opts.cmd == nil then
        opts.cmd = "echo 'ERROR: no cmd passed!'"
    end
    -- We need to create the buffer, then send the keys over, those keys being "clear; <cmd>"
end

term_cmd{cmd = "echo 'nuts'"}

-- [[ 
-- TODO: Add terminal functionality using the built in API.
--       NvChad uses vim.fn.termopen, which seemed promising, but there doesn't seem to be any documentation on it.
--       Also look into why people use opts rather than an actual list of parameters. It seems helpful, but also bad
--       for debugging and readability.
-- ]]

function read_config(config_f)
    -- Read in config
    local file = io.open(config_f, "r")
    local contents = {}
    contents["port"] = file:read()
    contents["fqbn"] = file:read()
    io.close(file)
    return contents
end

function M.compile(config_f)
    local conf = read_config(config_f)
    local program = vim.cmd("echo expand('%:p')")
    local cmd = "arduino-cli compile --fqbn "..conf["fqbn"].." "..program
    nvc_term.runner {
        pos = "sp",
        cmd = cmd,
        id = "arduino",
        clear_cmd = false
    }
    return conf, program -- return for upload below 
end

-- upload compiles again - may be changed in future
function M.upload(config_f)
    conf, program = M.compile(config_f)
    local cmd = "arduino-cli upload -p "..conf["port"].." --fqbn "..conf["fqbn"].." "..program
    nvc_term.runner {
        pos = "sp",
        cmd = cmd,
        id = "arduino",
        clear_cmd = false
    }
end



-- @params info -- a list containing info on whether this is port or core details, and the details of the core/port
--
-- The general idea here is we read the whole config file into a table, then edit the necessary line, then write the whole file back
function M.edit_config(info, config_f)
    local contents = read_config(config_f)
    -- Edit core/port field
    if info.type == "board" then
        contents["fqbn"] = info.value[2]
    elseif info.type == "port" then
        contents["port"] = info.value
    end
    -- Write config back
    local file = io.open(config_f, "w")
    str_contents = contents["port"].."\n"..contents["fqbn"].."\n"
    file:write(str_contents)
    io.close(file)
end


function M.test(x)
    print(x)
end



-- should I put the binds here?
    

return M
