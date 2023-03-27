local M = {}

function M.filter_empties(list)
  local non_empties = {}

  for i, value in ipairs(list) do
    if value ~= '' then
      non_empties[#non_empties + 1] = value
    end
  end

  return non_empties
end

function M.starts_with(str, start)
  return str:sub(1, #start) == start
end

return M
