local action_state = require("telescope.actions.state")
local action_utils = require("telescope.actions.utils")
local finders = require("telescope._extensions.presence.finders")

local M = {}

-- deleted marks buffer, used for later paste
M.mark_positions = {}

M.delete_mark_selections = function(opts)
  return function(prompt_bufnr)
    M.mark_positions = {} -- clear the buffer

    -- get selections
    local selections = {}
    action_utils.map_selections(prompt_bufnr, function(entry)
      table.insert(selections, entry)
    end)

    -- delete a mark
    local function delmark(mark)
      -- remember the mark-position for paste later
      local position = vim.fn.getpos("'" .. mark)
      table.insert(M.mark_positions, position)

      if vim.fn.match(mark, "\\C[A-Z]") == 0 then -- global mark
        vim.api.nvim_del_mark(mark)
      elseif vim.fn.match(mark, "\\C[a-z]") == 0 then -- local mark
        vim.api.nvim_buf_del_mark(opts.bufnr, mark)
      end
    end

    local index = 1

    if #selections > 0 then
      -- delete marks from multi-selection
      for i = #selections, 1, -1 do
        local selection = selections[i]
        index = selection.index
        local mark = string.sub(selection.ordinal, 1, 1)
        delmark(mark)
      end
    else
      -- delete marks from single-selection
      local selection = action_state.get_selected_entry()
      if selection ~= nil then
        index = selection.index
        local mark = string.sub(selection.ordinal, 1, 1)
        delmark(mark)
      else
        return
      end
    end

    -- remove the gaps in the marks_list
    vim.fn["presence#remove_gaps_in_marks_list"]()

    -- refresh the marks-picker
    local current_picker = action_state.get_current_picker(prompt_bufnr)
    local finder = finders.build_finder(opts)
    current_picker:refresh(finder, { reset_prompt = false })

    -- select the entry before the deleted selections
    vim.wait(1) -- wait for the refresh
    current_picker:set_selection(index - 1) -- select the entry
  end
end

M.paste_mark_selections = function(opts, insert_after)
  return function(prompt_bufnr)
    -- insert the positions of the deleted marks
    local selection = action_state.get_selected_entry()
    local mark = selection and string.sub(selection.ordinal, 1, 1) or nil
    local after = selection and insert_after or nil
    for _, position in ipairs(M.mark_positions) do
      vim.fn["presence#insert_global_mark_and_shift_backward"](
        mark,
        position,
        after
      )
    end

    -- clear the buffer
    M.mark_positions = {}

    -- get the index for the entry that was pasted; before or after
    local index = 0
    if selection then
      index = selection.index
      if insert_after == 1 then
        index = index + 1
      end
    end

    -- refresh the marks-picker
    local current_picker = action_state.get_current_picker(prompt_bufnr)
    local finder = finders.build_finder(opts)
    current_picker:refresh(finder, { reset_prompt = false })
    if selection then
      -- select the entry at the found index
      vim.wait(1) -- wait for the refresh
      current_picker:set_selection(index - 1) -- select the entry
    end
  end
end

return M
