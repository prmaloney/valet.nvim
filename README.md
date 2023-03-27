<p align="center">
  <h2 align="center">Valet.nvim</h2>
</p>

<p align="center">
  <img src="keep-it-running.gif" width="500" >
</p>

<p align="center">
Keep track of all the commands you want to have running automatically in each project
</p>

## Motivation

I got tired of running the same commands every time I start up a particular
project, mainly for web projects. As soon as I open neovim it would be really
cool to have a dev server already running.

This plugin allows you to specify a
project from it's root directory, and associate one or more commands to run as
soon as neovim is started from that project (or any of its subdirectories).

## Requirements

- Neovim >= 0.7.0
- [nvim-lua/plenary.nvim](https://github.com/nvim-lua/plenary.nvim) (if you use
  Telescope you already have this)

## Installation

- Lazy:

```lua
{'prmaloney/valet.nvim', config = true},
```

- Packer:

```lua
use {
  'prmaloney/valet.nvim',
  config = function()
      require('valet').setup()
    end
  }
```

## Configuration

Valet accepts the following parameters:

```lua
require('valet').setup({
    -- boolean to delete buffers if completed, default false
    delete_finished = false,
    -- function to run after all commands are started
    after_all = function() print('done!') end
  })
```

## Usage

valet.nvim exposes commands which are also associated with a lua api.

<!-- commands:start -->

| Command               | lua                                 | description                               |
| --------------------- | ----------------------------------- | ----------------------------------------- |
| `:ValetAddCommand`    | `require('valet').new_command()`    | add a new command for the current project |
| `:ValetDeleteCommand` | `require('valet').delete_command()` | delete a command for the current project  |
| `:ValetToggleMenu`    | `require('valet.ui').toggle_menu()` | toggle the menu to edit valet commands    |

<!-- commands:end -->

There's also some functions that don't have a command associated with them,
since I think they're probably less common to use. Still nice to have though.

| function                             | description                                    |
| ------------------------------------ | ---------------------------------------------- |
| `require('valet').print_projects()`  | print out all projects registered with valet   |
| `require('valet').delete_project()`  | delete a project                               |
| `require('valet').clear_projects()`  | clear all projects (use this _very_ carefully) |
| `require('valet').print_commands()`  | view all commands for the current project      |
| `require('valet).restart_commands()` | restart all commands for the current project   |

## Roadmap

- [x] A nicer UI (`vim.input` and `vim.select` are a good place to start, but we can
      probably do better)
- [ ] Add support for running commands using a specified terminal plugin (i.e.
      floatterm, toggleterm, etc.)
- [ ] Allow specifying an order to the commands to run (i.e. if you need to run a build before starting
      another command)
- [x] Maybe a way to 'close on finish' to avoid polluting with term buffers

## Thanks

A lot of this was heavily inspired by [Harpoon](https://github.com/ThePrimeagen/harpoon), which is a fantastic plugin if you're not already using it.
