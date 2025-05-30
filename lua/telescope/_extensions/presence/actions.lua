local action_state = require("telescope.actions.state")
local action_utils = require("telescope.actions.utils")

local M = {}

M.delete_mark_selections = function(opts)
  return function(prompt_bufnr)
    -- get selections
    local selections = {}
    action_utils.map_selections(prompt_bufnr, function(entry)
      table.insert(selections, entry)
    end)

    -- delete a mark
    local function delmark(mark)
      if vim.fn.match(mark, "\\C[A-Z]") == 0 then -- global mark
        vim.api.nvim_del_mark(mark)
      elseif vim.fn.match(mark, "\\C[a-z]") == 0 then -- local mark
        vim.api.nvim_buf_del_mark(opts.bufnr, mark)
      end
    end

    if #selections > 0 then
      -- delete marks from multi-selection
      for i = #selections, 1, -1 do
        local selection = selections[i]
        local mark = string.sub(selection.ordinal, 1, 1)
        delmark(mark)
      end
    else
      -- delete marks from single-selection
      local selection = action_state.get_selected_entry()
      if selection ~= nil then
        local mark = string.sub(selection.ordinal, 1, 1)
        delmark(mark)
      else
        return
      end
    end

    -- delete picker-selections
    local current_picker = action_state.get_current_picker(prompt_bufnr)
    current_picker:delete_selection(function() end)
  end
end

return M
