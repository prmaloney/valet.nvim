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

return M
