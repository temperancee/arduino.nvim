local M = {}

local util = require "arduino.util"

---@param current_file_path string
---@return string[]? splt #The current file path split at each slash, or nil on failure
local function check_file_is_ino(current_file_path)
    -- Split at each directory
    local splt = util.split(current_file_path, "/")
    -- Check the current file is indeed a .ino file - first split the file name into just the extension
    local current_file_name = util.split(splt[#splt], ".")
    if current_file_name[#current_file_name] ~= "ino" then
        vim.print("ERROR: The current buffer does not contain a .ino file")
        return nil
    end
    return splt
end

---@param current_file_path string #file path to current .ino file
---@return string? config_f #sketch.yaml file path
local function get_config_file(current_file_path)
    local splt = check_file_is_ino(current_file_path)
    -- propagate error forwards if necessary
    if splt == nil then
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
        return nil
    end
    local contents = {}
    -- The config file is a yaml file. We know exactly where the entries start (15 characters in), so we read from there
    contents["fqbn"] = file:read():sub(15)
    contents["port"] = file:read():sub(15)
    io.close(file)
    return contents
end

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
    if file == nil then
        vim.print("ERROR: Opening sketch.yaml file failed")
        return nil
    end
    local success, err = file:write(str_contents)
    io.close(file)
    if success == nil then
        vim.print("Writing to sketch.yaml failed, ERROR: "..err)
        return nil
    end
    return 0
end


---@return number? #0 on success, nil for failure
--- Creates a new arduino sketch, and configuration file 
-- TODO: 
-- Add parameter to customise the arduino_path
-- Open the newly created file in the buffer, if it is empty, if it is not, provide dialouge to open it
function M.create_file()
    -- Get new file name input
    local new_file_name = ""
    vim.ui.input({ prompt = "Enter name for new sketch: " }, function(input)
        new_file_name = input
    end)
    local arduino_path = "$HOME/Programming/arduino/"
    local ino_file = arduino_path..new_file_name
    local cmd_result = io.popen("arduino-cli sketch new "..ino_file)
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
        if M.create_config_file(ino_file) then
            return 0
        else
            return nil
        end
    end
end

---@param ino_file string
---@return number? #0 on success, nil on failure
function M.create_config_file(ino_file)
    local default_port = "/dev/ttyACM0"
    local default_core = "arduino:avr:uno"
    local cmd_result = io.popen("arduino-cli board attach -p "..default_port.." -b "..default_core.." "..ino_file)
    if cmd_result == nil then
        vim.print("Creating configuration file failed, is arduino-cli installed?")
        return nil
    else
        vim.print("Configuration file created successfully")
        return 0
    end
end


---@return number? #0 on success, nil on failure
---Create the config file for the .ino file in the current buffer
function M.create_current_config_file()
    local current_file_path = vim.api.nvim_buf_get_name(0)
    if check_file_is_ino(current_file_path) == nil then
        return nil
    end
    M.create_config_file(current_file_path)
    return 0
end

return M
