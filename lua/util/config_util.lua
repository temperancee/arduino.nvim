
local misc_util = require "util.misc_util"

local M = {}

---@param current_file_path string
---@return string[]? splt #The current file path split at each slash, or nil on failure
function M.check_file_is_ino(current_file_path)
    -- First, check the path isn't nil
    -- vim.print("cfp: "..current_file_path)
    if current_file_path == nil then
        vim.print("ERROR: This is not a .ino file")
        return nil
    end
    -- Split at each directory
    local splt = misc_util.split(current_file_path, "/")
    -- Check the current file is indeed a .ino file - first split the file name into just the extension
    local current_file_name = misc_util.split(splt[#splt], ".")
    if current_file_name[#current_file_name] ~= "ino" then
        vim.print("ERROR: This is not a .ino file")
        return nil
    end
    return splt
end


---@param current_file_path string #file path to current .ino file
---@return string? config_f #sketch.yaml file path
function M.get_config_file(current_file_path)
    local splt = M.check_file_is_ino(current_file_path)
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



---@param config_f string The path of the sketch.yaml file
---@return {fqbn: string, port: string}? #Configuration details, nil for error
--- Reads in the config by getting the currently open file (assumed to be the .ino file - we check this and send an error message otherwise), then navigating to the sketch.yaml file in that directory
function M.read_config(config_f)
    -- Read from the config file, checking if it exists
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

return M
