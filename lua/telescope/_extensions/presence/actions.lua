local action_state = require("telescope.actions.state")
local action_utils = require("telescope.actions.utils")

local M = {}

M.delete_mark_selections = function(prompt_bufnr)
  -- get selections
  local selections = {}
  action_utils.map_selections(prompt_bufnr, function(entry)
    table.insert(selections, entry)
  end)

  if #selections > 0 then
    -- delete marks from multi-selection
    for i = #selections, 1, -1 do
      local selection = selections[i]
      local mark = string.sub(selection.ordinal, 1, 1)
      vim.api.nvim_del_mark(mark)
    end
  else
    -- delete marks from single-selection
    local selection = action_state.get_selected_entry()
    if selection ~= nil then
      local mark = string.sub(selection.ordinal, 1, 1)
      vim.api.nvim_del_mark(mark)
    else
      return
    end
  end

  -- delete picker-selections
  local current_picker = action_state.get_current_picker(prompt_bufnr)
  current_picker:delete_selection(function() end)
end

return M
