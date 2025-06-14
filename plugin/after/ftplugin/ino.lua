if not vim.g.loaded_arduino_lists then
    vim.print("works")
end
-- NOTE: Using vim.g.loaded_ prevents the plugin from initializing twice
-- and allows users to prevent plugins from loading (in both Lua and Vimscript).
vim.g.loaded_arduino_lists = true

-- Set keymaps and user commands only in the current buffer (.ino file)
local bufnr = vim.api.nvim_get_current_buf()
local function board()
    require("pickers").board()
end
vim.api.nvim_create_user_command("Arduino Board", board, { desc = "Arduino board picker" })
vim.keymap.set("n", "<leader>ab", board, { desc = "Arduino board picker", buffer = bufnr })

local function port()
    require("pickers").port()
end
vim.api.nvim_create_user_command("Arduino Port", port, { desc = "Arduino port picker" })
vim.keymap.set("n", "<leader>ap", port, { desc = "Arduino port picker", buffer = bufnr})

local function refresh_lists()
    require("pickers").refresh_lists()
end
vim.api.nvim_create_user_command("Arduino Refresh", refresh_lists, { desc = "Arduino refresh picker lists" })
vim.keymap.set("n", "<leader>ar", refresh_lists, { desc = "Arduino refresh picker lists", buffer = bufnr})
