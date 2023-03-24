local popup = require('plenary.popup')

Valet_win_id = nil
Valet_bufh = nil

local M = {}

local function create_window()
  local current_project = require('valet.project').get_current_project()
  if not current_project then
    require('valet.project').create_project()
    current_project = require('valet.project').get_current_project()
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
  require('valet').save_config(commands)

  vim.api.nvim_win_close(Valet_win_id, true)

  Valet_win_id = nil
  Valet_bufh = nil
end

function M.toggle_menu()
  if Valet_win_id ~= nil and vim.api.nvim_win_is_valid(Valet_win_id) then
    close_menu()
    return
  end

  local win_info = create_window()
  local contents = require('valet.project').get_project_commands()

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
    "<Cmd>lua require('valet.ui').toggle_menu()<CR>",
    { silent = true }
  )
  vim.api.nvim_buf_set_keymap(
    Valet_bufh,
    "n",
    "<ESC>",
    "<Cmd>lua require('valet.ui').toggle_menu()<CR>",
    { silent = true }
  )
  vim.api.nvim_create_autocmd('BufWriteCmd', {
    buffer = Valet_bufh,
    callback = function()
      local lines = vim.api.nvim_buf_get_lines(Valet_bufh, 0, -1, true)
      require('valet').save_config(lines)
    end
  })
  vim.api.nvim_create_autocmd('BufModifiedSet', {
    buffer = Valet_bufh,
    callback = function()
      vim.bo.modified = false
    end
  })
  vim.api.nvim_create_autocmd('BufLeave', {
    nested = true,
    once = true,
    callback = function() require('valet.ui').toggle_menu() end
  })
end

return M
