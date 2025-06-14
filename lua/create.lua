local M = {}

local config_util = require "util.config_util"

---@return number? #0 on success, nil for failure
--- Creates a new arduino sketch, and configuration file 
-- TODO: 
-- Add parameter to customise the arduino_path
-- Open the newly created file in the buffer, if it is empty, if it is not, provide dialouge to open it
function M.create_sketch()
    -- Get new file name input
    local new_file_name = ""
    vim.ui.input({ prompt = "Enter name for new sketch: " }, function(input)
        new_file_name = input
        vim.print("\n")
    end)
    local arduino_path = "~/Programming/arduino/"
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
        ino_file = ino_file.."/"..new_file_name..".ino" -- append on actual sketch file for passing to create_config_file
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
    local splt = config_util.check_file_is_ino(ino_file)
    -- propagate errors
    if splt == nil then
        vim.print("ERROR: Failed to create configuration file")
        return nil
    end
    -- Check if there is already a sketch.yaml file
    splt[#splt] = "sketch.yaml"
    if vim.fn.filereadable("/"..table.concat(splt, "/")) == 1 then -- see config_util.check_file_is_ino() for explanation of the concatenation
        vim.print("/"..table.concat(splt, "/"))
        vim.print("Configuration file already exists")
        return nil
    end
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
    -- propagate errors
    if M.create_config_file(current_file_path) == nil then
        return nil
    end
    return 0
end

return M
