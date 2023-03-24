local Path = require('plenary.path')
local popup = require('plenary.popup')
require('harpoon.ui')

local cache_path = vim.fn.stdpath("data")
local cache_config = string.format("%s/valet.json", cache_path)

local M = {}

Valet_win_id = nil
Valet_bufh = nil

local function read_config(local_config)
  return vim.json.decode(Path:new(local_config):read())
end


local function create_project()
  vim.ui.input({
    prompt = 'Project root directory: ',
    default = vim.fn.getcwd()
  }, function(input)
    if input == nil then return end

    ValetConfig.projects[input] = {}
    M.save_config()
  end)
end


local function get_current_project()
  if next(ValetConfig.projects) == nil then return end

  local projects = vim.fn.keys(ValetConfig.projects)
  local cwd = vim.fn.getcwd()

  local function starts_with(str, start)
    return str:sub(1, #start) == start
  end

  for _, project_dir in ipairs(projects) do
    if starts_with(cwd, project_dir) then return project_dir end
  end
end

local function get_project_commands()
  local project = get_current_project()

  return ValetConfig.projects[project]
end


local function create_window()
  local current_project = get_current_project()
  if not current_project then
    create_project()
    current_project = get_current_project()
  end
  local width = 60
  local height = 10
  local borderchars = { "─", "│", "─", "│", "╭", "╮", "╯", "╰" }
  local bufnr = vim.api.nvim_create_buf(false, false)

  local Valet_win_id, _ = popup.create(bufnr, {
    title = "Valet",
    line = math.floor(((vim.o.lines - height) / 2) - 1),
    col = math.floor((vim.o.columns - width) / 2),
    minwidth = width,
    minheight = height,
    borderchars = borderchars,
  })

  return {
    bufnr = bufnr,
    win_id = Valet_win_id,
  }
end

local function close_menu()
  local commands = vim.api.nvim_buf_get_lines(Valet_bufh, 0, -1, true)
  M.save_config(commands)

  vim.api.nvim_win_close(Valet_win_id, true)

  Valet_win_id = nil
  Valet_bufh = nil
end

function M.save_config(commands)
  if commands ~= nil then
    ValetConfig.projects[get_current_project()] = commands
  end
  local config_to_save = { projects = ValetConfig.projects }
  Path:new(cache_config):write(vim.fn.json_encode(config_to_save), 'w')
end

function M.toggle_menu()
  if Valet_win_id ~= nil and vim.api.nvim_win_is_valid(Valet_win_id) then
    close_menu()
    return
  end

  local win_info = create_window()
  local contents = get_project_commands()

  Valet_win_id = win_info.win_id
  Valet_bufh = win_info.bufnr

  vim.api.nvim_win_set_option(Valet_win_id, "number", true)
  vim.api.nvim_buf_set_name(Valet_bufh, "valet-menu")
  vim.api.nvim_buf_set_lines(Valet_bufh, 0, #contents, false, contents)
  vim.api.nvim_buf_set_option(Valet_bufh, "filetype", "valet")
  vim.api.nvim_buf_set_option(Valet_bufh, "buftype", "acwrite")
  vim.api.nvim_buf_set_option(Valet_bufh, "bufhidden", "delete")
  vim.api.nvim_buf_set_keymap(
    Valet_bufh,
    "n",
    "q",
    "<Cmd>lua require('valet').toggle_menu()<CR>",
    { silent = true }
  )
  vim.api.nvim_buf_set_keymap(
    Valet_bufh,
    "n",
    "<ESC>",
    "<Cmd>lua require('valet').toggle_menu()<CR>",
    { silent = true }
  )
  vim.api.nvim_create_autocmd('BufWriteCmd', {
    buffer = Valet_bufh,
    callback = function()
      local lines = vim.api.nvim_buf_get_lines(Valet_bufh, 0, -1, true)
      M.save_config(lines)
    end
  })
  -- vim.cmd(
  --   string.format(
  --     "autocmd BufModifiedSet <buffer=%s> set nomodified",
  --     Valet_bufh
  --   )
  -- )
  vim.api.nvim_create_autocmd('BufModifiedSet', {
    buffer = Valet_bufh,
    callback = function()
      vim.bo.modified = false
    end
  })
  vim.cmd(
    "autocmd BufLeave <buffer> ++nested ++once silent lua require('valet').toggle_menu()"
  )
end

local function start_commands()
  local commands = get_project_commands()
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
  local current_project = get_current_project()
  if not current_project then
    create_project()
    current_project = get_current_project()
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
  local commands = get_project_commands()

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
  local commands = get_project_commands()
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

  vim.api.nvim_create_user_command('ValetToggleMenu', M.toggle_menu, {})
  vim.api.nvim_create_user_command('ValetNewCommand', M.new_command, {})
  vim.api.nvim_create_user_command('ValetDeleteCommand', M.delete_command, {})

  vim.api.nvim_create_augroup('Valet', { clear = true })
  vim.api.nvim_create_autocmd('VimEnter', {
    group = 'Valet',
    callback = start_commands
  })
end

return M
