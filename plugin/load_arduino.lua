local function compile()
    require("compilation").compile()
end
vim.api.nvim_create_user_command("Arduino Compile", compile, { desc = "Arduino compile sketch" })
vim.keymap.set("n", "<leader>ac", compile, { desc = "Arduino compile sketch" })

local function upload()
    require("compilation").upload()
end
vim.api.nvim_create_user_command("Arduino Upload", upload, { desc = "Arduino upload sketch" })
vim.keymap.set("n", "<leader>au", upload, { desc = "Arduino upload sketch" })

local function create_sketch()
    require("create").create_sketch()
end
vim.api.nvim_create_user_command("Arduino Sketch", create_sketch, { desc = "Arduino create new sketch" })
vim.keymap.set("n", "<leader>an", create_sketch, { desc = "Arduino create new sketch" })

local function create_current_config_file()
    require("create").create_current_config_file()
end
vim.api.nvim_create_user_command("Arduino Config", create_current_config_file, { desc = "Arduino create config file for current sketch" })
vim.keymap.set("n", "<leader>ag", create_current_config_file, { desc = "Arduino create config file for current sketch" })



-- NOTE:
-- This plugin is actually multiple different plugins
-- The functionality of board and port picking is entirely unrelated in implementation to compiling and uploading. Creating files is almost entirely unrelated from these other two functions, however, it would be beneficial to fill the configuration file with the board and port previously chosen if the pickers had been opened recently. This, however, would be best achieved, I believe, by simply reading the configuration file of the currently open buffer (if it contains a .ino file), and copying it to be the new config file. Creation is indeed separate from picking and compiling/uploading.
-- Thus, this is really 3 plugins grouped together, since they all relate to Arduino
--
-- TODO:
-- Edit the create file function as specified above
