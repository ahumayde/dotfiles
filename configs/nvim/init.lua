-- ~/.config/nvim/init.lua
-- Entry point. Keep this file tiny :)

require("config.options")
require("config.keymaps")
require("config.autocmds")

require("lazy-bootstrap")
require("lazy-plugins")
