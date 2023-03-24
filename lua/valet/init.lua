local Path = require('plenary.path')
require('harpoon.ui')

local cache_path = vim.fn.stdpath("data")
local cache_config = string.format("%s/valet.json", cache_path)

local M = {}

local function read_config(local_config)
  return vim.json.decode(Path:new(local_config):read())
end

function M.save_config(commands)
  if commands ~= nil then
    ValetConfig.projects[require('valet.project').get_current_project()] = commands
  end
  local config_to_save = { projects = ValetConfig.projects }
  Path:new(cache_config):write(vim.fn.json_encode(config_to_save), 'w')
end

local function start_commands()
  local commands = require('valet.project').get_project_commands()
  if (commands == nil or #commands == 0) then return end

  local mainbuf = vim.api.nvim_get_current_buf()
  for _, command in ipairs(commands) do
    vim.cmd('term')
    ---@diagnostic disable-next-line: undefined-field
    local term_id = vim.b.terminal_job_id

    vim.api.nvim_chan_send(term_id, command .. '\r')
  end
  vim.api.nvim_set_current_buf(mainbuf)

  if ValetConfig.after_all then
    ValetConfig.after_all()
  end
end

function M.restart_commands()
  start_commands()
end

function M.new_command()
  local current_project = require('valet.project').get_current_project()
  if not current_project then
    require('valet.project').create_project()
    current_project = require('valet.project').get_current_project()
  end

  vim.ui.input({ prompt = 'Enter new valet command for ' .. current_project .. ': ' }, function(command)
    if command == nil then return end

    table.insert(ValetConfig.projects[current_project], command)
    M.save_config()
  end)
end

function M.delete_project()
  vim.ui.select(vim.fn.keys(ValetConfig.projects),
    { prompt = 'Select project to delete' },
    function(selection)
      if selection == nil then return end

      ValetConfig.projects[selection] = nil
      M.save_config()
    end
  )
end

function M.delete_command()
  local commands = require('valet.project').get_project_commands()

  vim.ui.select(commands,
    { prompt = 'Select a command to delete' },
    function(selection)
      if selection == nil then return end

      for i, cmd in ipairs(commands) do
        if cmd == selection then
          table.remove(commands, i)
          M.save_config()
        end
      end
    end
  )
end

function M.print_commands()
  local commands = require('valet.project').get_project_commands()
  print(vim.inspect(commands))
end

function M.clear_projects()
  vim.ui.select({ 'yes', 'no' },
    { prompt = 'Are you sure? (you cannot undo this)' },
    function(selection)
      if selection ~= 'yes' then
        ValetConfig.projects = {}
      end
    end
  )
  M.save_config()
end

function M.print_projects()
  print(vim.inspect(vim.fn.keys(ValetConfig.projects)))
end

function M.get_valet_config()
  return ValetConfig
end

function M.setup(config)
  config = config or {}
  local ok, c_config = pcall(read_config, cache_config)
  if ok then
    ValetConfig = vim.tbl_deep_extend('keep', config, c_config)
  else
    ValetConfig = vim.tbl_deep_extend('keep', config, { projects = {} })
  end
  M.save_config()

  vim.api.nvim_create_user_command('ValetToggleMenu', require('valet.ui').toggle_menu, {})
  vim.api.nvim_create_user_command('ValetNewCommand', M.new_command, {})
  vim.api.nvim_create_user_command('ValetDeleteCommand', M.delete_command, {})

  vim.api.nvim_create_augroup('Valet', { clear = true })
  vim.api.nvim_create_autocmd('VimEnter', {
    group = 'Valet',
    callback = start_commands
  })
end

return M
