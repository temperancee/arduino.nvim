local M = {}

local util = require "arduino.util"


---@param current_file_path string #file path to current .ino file
---@return string? config_f #sketch.yaml file path
local function get_config_file(current_file_path)
    -- Split at each directory
    local splt = util.split(current_file_path, "/")
    -- Check the current file is indeed a .ino file - first split the file name into just the extension
    local current_file_name = util.split(splt[#splt], ".")
    if current_file_name[#current_file_name] ~= "ino" then
        vim.print("ERROR: The current buffer does not contain a .ino file")
        local err_file = io.open("~/err_file.txt", "w")
        err_file:write("ERROR: The current buffer does not contain a .ino file")
        io.close(err_file)
        return nil
    end
    -- replace the .ino file with "sketch.yaml" and rejoin the string to get the config filepath
    splt[#splt] = "sketch.yaml"
    local config_f = table.concat(splt, "/")
    config_f = "/" .. config_f -- Need to append the leading slash onto the front of the filepath, as this will not be added back by concat
    return config_f
end



---@param current_file_path string The path of the current .ino file
---@return {fqbn: string, port: string}? #Configuration details, nil for error
--- Reads in the config by getting the currently open file (assumed to be the .ino file - we check this and send an error message otherwise), then navigating to the sketch.yaml file in that directory
local function read_config(current_file_path)
    local config_f = get_config_file(current_file_path)
    -- propagate the nil from get_config_file through the system, if there is no .ino file
    if config_f == nil then
        return nil
    end
    -- Now read from the config file, checking if it exists
    local file = io.open(config_f, "r")
    if file == nil then
        vim.print("ERROR: No sketch.yaml found in project directory")
        vim.print("Trying to access "..config_f)
        local err_file = io.open("~/err_file.txt", "w")
        err_file:write("ERROR: No sketch.yaml found in project directory")
        io.close(err_file)
        return nil
    end
    local contents = {}
    -- The config file is a yaml file, so we want to split at the space to get the entry. This works because there are no spaces in the fqbns or ports
    -- TODO: It would probably be more efficient to simply substring the string, as we know exactly where the fqbn/port will start due to the fixed format
    contents["fqbn"] = util.split(file:read(), " ")[2]
    contents["port"] = util.split(file:read(), " ")[2]
    io.close(file)
    return contents
end

-- TODO: test that it all works and add documentation comments

---@return {conf: {fqbn: string, port: string}, program: string}? #Dictionary containing the configuration details and program name, nil for error
--- Compiles the arduino program in the current buffer using the fqbn specified in sketch.yaml
function M.compile()
    local program = vim.api.nvim_buf_get_name(0)
    local conf = read_config(program)
    if conf == nil then
        return nil
    end
    local cmd = "arduino-cli compile --fqbn "..conf["fqbn"].." "..program
    util.runner_term {
        cmd = cmd,
        id = "arduino",
    }
    return { conf=conf, program=program } -- return for upload below 
end



---@return number? #0 for success and nil for error
--- upload compiles again - may implement a check to see if we have already compiled in future
function M.upload()
    local prog_details = M.compile()
    if prog_details == nil then
        return nil
    else
        local cmd = "arduino-cli upload -p "..prog_details.conf["port"].." --fqbn "..prog_details.conf["fqbn"].." "..prog_details.program
        util.runner_term {
            cmd = cmd,
            id = "arduino",
        }
        return 0
    end
end



---@param info {type: string, value: any, display: string, ordinal: string } #a list containing info on whether this is port or core details, and the details of the core/port
---@return number? #0 for success, nil for error
--- The general idea here is we read the whole config file into a table, then edit the necessary line, then write the whole file back
function M.edit_config(info)
    local current_file_path = vim.api.nvim_buf_get_name(0)
    local contents = read_config(current_file_path)
    -- propagate errros, could be either due to no .ino file or no sketch.yaml file
    if contents == nil then
        return nil
    end
    -- Edit core/port field
    if info.type == "board" then
        contents["fqbn"] = info.value[2]
    elseif info.type == "port" then
        contents["port"] = info.value
    end
    -- Write config back
    local config_f = get_config_file(current_file_path)
    -- propagate possible nil from get_config_file due to no .ino file through the system
    if config_f == nil then
        return nil
    end
    local file = io.open(config_f, "w")
    local str_contents = "default_fqbn: "..contents["fqbn"].."\ndefault_port: "..contents["port"]
    local success, err = file:write(str_contents) -- IDK why the LSP thinks I haven't nil checked this
    io.close(file)
    if success == nil then
        vim.print("Writing to sketch.yaml failed, ERROR: "..err)
        local err_file = io.open("~/err_file.txt", "w")
        err_file:write("Writing to sketch.yaml failed, ERROR: "..err)
        io.close(err_file)
        return nil
    end
    return 0
end

vim.ui.input({ prompt="test" }, function (input)
    vim.print(input)
end)

---@return number? #0 on success, nil for failure
--- Creates a new arduino sketch, and configuration file (TODO:)
--- TODO: Add section to create new configuration file, and add parameter to customise the arduino_path
function M.create_file()
    -- Get new file name input
    local new_file_name = ""
    vim.ui.input({ prompt = "Enter name for new sketch: " }, function(input)
        new_file_name = input
    end)
    local arduino_path = "$HOME/Programming/arduino/"
    local cmd_result = io.popen("arduino-cli sketch new "..arduino_path..new_file_name)
    if cmd_result == nil then
        if cmd_result == nil and new_file_name == "" then
            vim.print("ERROR: No name entered")
            return nil
        else
            vim.print("Creating new sketch failed, is arduino-cli installed?")
            return nil
        end
    else
        vim.print(cmd_result:read())
        return 0
    end
end

function M.create_config_file()
    local default_port = "/dev/ttyACM0"
    local default_core = "arduino:avr:uno"
    local cmd = "arduino-cli board attach -p "..default_port.." -b arduino:avr:uno test.ino"
end

-- should I put the binds here?

return M
