
local M = {}

function M.compile(fqbn, file)
    os.execute("arduino-cli compile --fqbn "..fqbn.." "..file)
end

function M.upload(port, fqbn, file)
    os.execute("arduino-cli upload -p "..port.." --fqbn "..fqbn.." "..file)
end



-- @params info -- a list containing info on whether this is port or core details, and the details of the core/port
--
-- The general idea here is we read the whole config file into a table, then edit the necessary line, then write the whole file back
function M.edit_config(info, config_f)
    -- Read in config
    local file = io.open(config_f, "r")
    local contents = {}
    local i = 1
    for line in file:lines() do
        contents[i] = line
        i=i+1
    end
    io.close(file)
    -- Edit core/port field
    if info.type == "board" then
        contents[2] = "fqbn = "..info.value[2]
    elseif info.type == "port" then
            -- TODO:
        contents[1] = "eggs"
    end
    -- Write config back
    local file = io.open(config_f, "w")
    str_contents = contents[1].."\n"..contents[2].."\n"
    file:write(str_contents)
    io.close(file)
end


function M.test(x)
    print(x)
end



-- should I put the binds here?
    

return M
