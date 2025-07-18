-- TODO:
-- The biggest and most important TODO of all (that has nothing to do with this file)
-- The arduino-language-server can be configured to run on both ino and cpp files
-- However, we also have clangd installed, and want this to run on cpp files that are not part of an Arduino project
-- Currently, if we enable both, the cpp files will be dealt with by clangd (bad) and only the ino file will use arduino-language-server
-- We need a way to fix this
-- Another issue is that the arduino-language-server takes an FQBN as input in the lspconfig. This means we need to change this each time we update the board choice...



local M = {}

local config_util = require "util.config_util"

---Creates a new arduino sketch and associated configuration file 
---@return number? #0 on success, nil for failure
-- TODO: 
-- Add parameter to customise the arduino_path
function M.create_sketch()
    -- Get new file name input
    local new_file_name = ""
    vim.ui.input({ prompt = "Enter name for new sketch: " }, function(input)
        new_file_name = input
    end)
    -- Filename validation
    local success, err = config_util.is_valid_filename(new_file_name)
    if not success then
        vim.notify(err, vim.log.levels.ERROR)
        return nil
    end
    -- Form full path
    local arduino_path = "~/Programming/arduino/"
    local ino_file = arduino_path..new_file_name
    -- Create new sketch
    local cmd_result = io.popen("arduino-cli sketch new "..ino_file)
    if cmd_result == nil then
        vim.notify("Creating new sketch failed, is arduino-cli installed?", vim.log.levels.ERROR)
        return nil
    end
    -- Create config file
    ino_file = ino_file.."/"..new_file_name..".ino" -- append on actual sketch file for passing to create_config_file
    if not M.create_config_file(ino_file) then
        return nil
    end
    -- Open the newly created file in the current buffer, if it is empty, if it is not, provide dialouge to open it
    if vim.api.nvim_buf_get_lines(0, 0, -1, false) == { "" } then
        vim.cmd.edit(ino_file)
    else
        vim.ui.input({ prompt = "Open the file in the current buffer? (Y/n)" }, function(input)
            if input ~= "n" then
                vim.cmd.edit(ino_file)
            end
        end)
    end
    return 0
end

---@param ino_file string
---@return number? #0 on success, nil on failure
-- TODO:
-- Add config for the default port and core
function M.create_config_file(ino_file)
    -- Returns the ino file path split on each /
    local splt = config_util.check_file_is_ino(ino_file)
    if splt == nil then
        return nil
    end
    -- Check if there is already a sketch.yaml file
    splt[#splt] = "sketch.yaml"
    if vim.fn.filereadable("/"..table.concat(splt, "/")) == 1 then
        vim.notify("Configuration file already exists", vim.log.levels.ERROR)
        return nil
    end
    local default_port = "/dev/ttyACM0"
    local default_core = "arduino:avr:uno"
    local cmd_result = io.popen("arduino-cli board attach -p "..default_port.." -b "..default_core.." "..ino_file)
    if cmd_result == nil then
        vim.notify("Creating configuration file failed, is arduino-cli installed?", vim.log.levels.ERROR)
        return nil
    else
        return 0
    end
end


---Create the config file for the .ino file in the current buffer
---@return number? #0 on success, nil on failure
function M.create_current_config_file()
    local current_file_path = vim.api.nvim_buf_get_name(0)
    if M.create_config_file(current_file_path) == nil then
        return nil
    end
    return 0
end

return M
