# arduino.nvim

Arduino integration within Neovim, using telescope. (Partially abandoned)

## Features
- Compile code via a keybind and see the output in a Neovim terminal
- Upload code as above
- Pick the board and port to compile/upload with using a telescope picker
- Create new sketches and configuration files within Neovim

## Prerequisites
- Install the [Arduino Language Server](https://github.com/arduino/arduino-language-server) (likely via [Mason](https://github.com/mason-org/mason.nvim))
- Install clangd (likely via [Mason](https://github.com/mason-org/mason.nvim))
- Install [arduino-cli](https://docs.arduino.cc/arduino-cli/)
