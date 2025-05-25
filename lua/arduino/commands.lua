
local nvc_term = require("nvchad.term")


local M = {}

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
