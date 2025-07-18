local M = {}

local config_util = require "util.config_util"

---@return number? #0 on success, nil for failure
--- Creates a new arduino sketch, and configuration file 
-- TODO: 
-- Add parameter to customise the arduino_path
-- Open the newly created file in the buffer, if it is empty, if it is not, provide dialouge to open it
function M.create_sketch()
    -- Initialise confirmation/error message to print at the end of the function
    local msg = {}
    -- Get new file name input
    local new_file_name = ""
    vim.ui.input({ prompt = "Enter name for new sketch: " }, function(input)
        new_file_name = input
    end)
    local arduino_path = "~/Programming/arduino/"
    local ino_file = arduino_path..new_file_name
    -- TODO:
    -- Need to also check that the filename isn't just illegal characters, e.g. "/////"
    if new_file_name == "" then
        table.insert(msg, "ERROR: No name entered")
        vim.print(table.concat(msg, "\n"))
        return nil
    end
    local cmd_result = io.popen("arduino-cli sketch new "..ino_file)
    if cmd_result == nil then
        table.insert(msg, "Creating new sketch failed, is arduino-cli installed?")
        vim.print(table.concat(msg, "\n"))
        return nil
    else
        table.insert(msg, cmd_result:read())
        ino_file = ino_file.."/"..new_file_name..".ino" -- append on actual sketch file for passing to create_config_file
        local status, return_msg = M.create_config_file(ino_file)
        for _,str in ipairs(return_msg) do
            table.insert(msg, str)
        end
        if status then
            vim.print(table.concat(msg, "\n"))
            return 0
        else
            vim.print(table.concat(msg, "\n"))
            return nil
        end
    end
    -- Print the built up confirmation/error message
end

---@param ino_file string
---@return number?, string[] msg #0 on success, nil on failure
function M.create_config_file(ino_file)
    -- Initialise confirmation/error message to print at the end of the function
    local msg = {}
    local splt, return_msg = config_util.check_file_is_ino(ino_file)
    for _,str in ipairs(return_msg) do
        table.insert(msg, str)
    end
    -- propagate errors
    if splt == nil then
        table.insert(msg, "ERROR: Failed to create configuration file")
        return nil, msg
    end
    -- Check if there is already a sketch.yaml file
    splt[#splt] = "sketch.yaml"
    if vim.fn.filereadable("/"..table.concat(splt, "/")) == 1 then -- see config_util.check_file_is_ino() for explanation of the concatenation
        table.insert(msg, "/"..table.concat(splt, "/"))
        table.insert(msg, "Configuration file already exists")
        return nil, msg
    end
    local default_port = "/dev/ttyACM0"
    local default_core = "arduino:avr:uno"
    local cmd_result = io.popen("arduino-cli board attach -p "..default_port.." -b "..default_core.." "..ino_file)
    if cmd_result == nil then
        table.insert(msg, "Creating configuration file failed, is arduino-cli installed?")
        return nil, msg
    else
        table.insert(msg, "Configuration file created successfully")
        return 0, msg
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
