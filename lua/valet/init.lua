local Path = require("plenary.path")

local cache_path = vim.fn.stdpath("data")
local cache_config = string.format("%s/valet.json", cache_path)

local M = {}

local function read_config(local_config)
  return vim.json.decode(Path:new(local_config):read())
end

local function save_config()
  local config_to_save = { projects = ValetConfig.projects }
  Path:new(cache_config):write(vim.fn.json_encode(config_to_save), 'w')
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

local function start_commands()
  local currentProject = get_current_project()
  if currentProject == nil then return end

  local commands = ValetConfig.projects[currentProject]
  if (commands == nil or #commands == 0) then return end

  local mainbuf = vim.api.nvim_get_current_buf()
  for _, command in ipairs(commands) do
    vim.cmd('term')
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

local function create_project()
  vim.ui.input({
    prompt = 'Project root directory: ',
    default = vim.fn.getcwd()
  }, function(input)
    if input == nil then return end

    ValetConfig.projects[input] = {}
    save_config()
  end)
end

function M.new_command()
  local currentProject = get_current_project()
  if currentProject == nil then
    create_project()
    currentProject = get_current_project()
  end

  vim.ui.input({ prompt = 'Enter new valet command for ' .. currentProject .. ': ' }, function(command)
    if command == nil then return end

    table.insert(ValetConfig.projects[currentProject], command)
    save_config()
  end)
end

function M.delete_project()
  vim.ui.select(vim.fn.keys(ValetConfig.projects),
    { prompt = 'Select project to delete' },
    function(selection)
      if selection == nil then return end

      ValetConfig.projects[selection] = nil
      save_config()
    end
  )
end

function M.delete_command()
  local currentProject = get_current_project()
  local commands = ValetConfig.projects[currentProject]

  vim.ui.select(commands,
    { prompt = 'Select a command to delete' },
    function(selection)
      if selection == nil then return end

      for i, cmd in ipairs(commands) do
        if cmd == selection then
          table.remove(commands, i)
          save_config()
        end
      end
    end
  )
end

function M.view_commands()
  local currentProject = get_current_project()
  if currentProject == nil then return end

  local commands = ValetConfig.projects[currentProject]
end

function M.clear_projects()
  vim.ui.select({ 'yes', 'no' },
    { prompt = 'Are you sure? (you cannot undo this)' },
    function(selection)
      if selection ~= 'yes' then
        ValetConfig.projects = {}
        save_config()
      end
    end
  )
  save_config()
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
  save_config()

  vim.api.nvim_create_user_command('ValetNewCommand', M.new_command, {})
  vim.api.nvim_create_user_command('ValetDeleteCommand', M.delete_command, {})

  vim.api.nvim_create_augroup('Valet', { clear = true })
  vim.api.nvim_create_autocmd('VimEnter', {
    group = 'Valet',
    callback = start_commands
  })
end

return M
