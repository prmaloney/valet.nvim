local Path = require("plenary.path")

local cache_path = vim.fn.stdpath("data")
local cache_config = string.format("%s/valet.json", cache_path)

local M = {}

local function read_config(local_config)
  return vim.json.decode(Path:new(local_config):read())
end

local function save_config()
  Path:new(cache_config):write(vim.fn.json_encode(ValetConfig), 'w')
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
end

function M.restart_commands()
  start_commands()
end

function M.new_project()
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
  if currentProject == nil then return end

  vim.ui.input({ prompt = 'Enter new valet command: ' }, function(command)
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
  print(vim.inspect(commands))
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

function M.setup()
  local ok, c_config = pcall(read_config, cache_config)
  if ok then
    ValetConfig = c_config
  else
    ValetConfig = { projects = {} }
  end
  save_config()

  vim.api.nvim_create_user_command('ValetNewProject', M.new_project, {})
  vim.api.nvim_create_user_command('ValetNewCommand', M.new_command, {})
  vim.api.nvim_create_user_command('ValetDeleteProject', M.delete_project, {})
  vim.api.nvim_create_user_command('ValetDeleteCommand', M.delete_command, {})

  vim.api.nvim_create_augroup('Valet', { clear = true })
  vim.api.nvim_create_autocmd('VimEnter', {
    group = 'Valet',
    callback = start_commands
  })
end

return M
