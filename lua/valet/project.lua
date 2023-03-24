local M = {}

function M.get_current_project()
  local config = require('valet').get_valet_config()
  if next(config.projects) == nil then return end

  local projects = vim.fn.keys(config.projects)
  local cwd = vim.fn.getcwd()

  local function starts_with(str, start)
    return str:sub(1, #start) == start
  end

  for _, project_dir in ipairs(projects) do
    if starts_with(cwd, project_dir) then return project_dir end
  end
end

function M.create_project()
  vim.ui.input({
    prompt = 'Project root directory: ',
    default = vim.fn.getcwd()
  }, function(input)
    if input == nil then return end

    local config = require('valet').get_valet_config()
    config.projects[input] = {}
    require('valet').save_config()
  end)
end

function M.get_project_commands()
  local project = M.get_current_project()
  local config = require('valet').get_valet_config()

  return config.projects[project]
end

return M
