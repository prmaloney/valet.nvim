local Path = require("plenary.path")

local cache_path = vim.fn.stdpath("data")
local cache_config = string.format("%s/autostart.json", cache_path)

local M = {}

local function read_config(local_config)
  return vim.json.decode(Path:new(local_config):read())
end

local function save_config()
  Path:new(cache_config):write(vim.fn.json_encode(AutostartConfig), 'w')
end

function get_current_project()
  local projects = vim.fn.keys(AutostartConfig)
  local cwd = vim.fn.getcwd()

  for _, project_dir in ipairs(projects) do
    if cwd:match('^' .. project_dir) == project_dir then return project_dir end
  end
end

function M.new_project()
  vim.ui.input({
    prompt = 'Project root directory: ',
    default = vim.fn.getcwd()
  }, function(input)
    if input == nil then return end

    AutostartConfig[input] = {}
    save_config()
  end)
end

function M.new_command()
  local currentProject = get_current_project()
  if currentProject == nil then return end

  vim.ui.input({ prompt = 'Enter new autostart command: ' }, function(command)
    if command == nil then return end

    table.insert(AutostartConfig[currentProject], command)
    save_config()
  end)
end

function M.delete_project()
  vim.ui.select(vim.fn.keys(AutostartConfig),
    { prompt = 'Select project to delete' },
    function(selection)
      if selection == nil then return end

      AutostartConfig[selection] = nil
      save_config()
    end
  )
end

function M.delete_command()
  local currentProject = get_current_project()
  local commands = AutostartConfig[currentProject]

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

function M.clear_projects()
  vim.ui.select({ 'yes', 'no' },
    { prompt = 'Are you sure? (you cannot undo this)' },
    function(selection)
      if selection ~= 'yes' then
        AutostartConfig = {}
        save_config()
      end
    end
  )
  AutostartConfig = {}
  save_config()
end

function M.print_projects()
  print(vim.inspect(AutostartConfig))
end

function M.setup(config)
  AutostartConfig = config or {}

  local ok, c_config = pcall(read_config, cache_config)
  if ok then
    AutostartConfig = vim.tbl_deep_extend("force", c_config, AutostartConfig)
  end
  save_config()

  vim.api.nvim_create_user_command('NewProject', M.new_project, {})
  vim.api.nvim_create_user_command('NewCommand', M.new_command, {})
  vim.api.nvim_create_user_command('DeleteProject', M.delete_project, {})
  vim.api.nvim_create_user_command('DeleteCommand', M.delete_command, {})

  vim.api.nvim_create_augroup('Autostart', { clear = true })
  vim.api.nvim_create_autocmd('VimEnter', {
    group = 'Autostart',
    callback = function()
      -- TODO: actual logic gets called here
    end
  })
end

return M
