local arduino = require("arduino")

return require("telescope").register_extension {
  setup = function(ext_config, config)
    -- access extension config and user config
  end,
  exports = {
    board = arduino.board,
    port = arduino.port
  },
}
