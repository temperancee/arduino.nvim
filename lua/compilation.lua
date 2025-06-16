local M = {}

local config_util = require "util.config_util"
local term_util = require "util.term_util"

---@return {conf: {fqbn: string, port: string}, program: string}? #Dictionary containing the configuration details and program name, nil for error
--- Compiles the arduino program in the current buffer using the fqbn specified in sketch.yaml
function M.compile()
    local program = vim.api.nvim_buf_get_name(0)
    local config_f = config_util.get_config_file(program)
    -- propagate error forwards if necessary
    if config_f == nil then
        return nil
    end
    local conf = config_util.read_config(config_f)
    if conf == nil then
        return nil
    end
    local cmd = "arduino-cli compile --fqbn "..conf["fqbn"].." --clean "..program
    term_util.runner_term {
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
        term_util.runner_term {
            cmd = cmd,
            id = "arduino",
        }
        return 0
    end
end

return M
