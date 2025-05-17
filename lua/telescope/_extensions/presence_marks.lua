local telescope = require("telescope")
local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local make_entry = require("telescope.make_entry")

local conf = require("telescope.config").values

local list_marks = function(opts)
  opts = opts or {}

  if opts.bufnr == nil then
    opts.bufnr = vim.api.nvim_get_current_buf()
  end

  local local_marks = {
    items = vim.fn.getmarklist(opts.bufnr),
    name_func = function(_, line)
      return vim.api.nvim_buf_get_lines(opts.bufnr, line - 1, line, false)[1]
    end,
  }
  local global_marks = {
    items = vim.fn.getmarklist(),
    name_func = function(mark, _)
      -- get buffer name if it is opened, otherwise get file name
      return vim.api.nvim_get_mark(mark, {})[4]
    end,
  }
  local marks_table = {}
  -- local marks_others = {}
  local bufname = vim.api.nvim_buf_get_name(opts.bufnr)
  for _, cnf in ipairs({ local_marks, global_marks }) do
    for _, v in ipairs(cnf.items) do
      -- strip the first single quote character
      local mark = string.sub(v.mark, 2, 3)
      local _, lnum, col, _ = unpack(v.pos)
      local name = cnf.name_func(mark, lnum)
      -- same format to :marks command
      local line = string.format("%s %6d %4d %s", mark, lnum, col - 1, name)
      local row = {
        line = line,
        lnum = lnum,
        col = col,
        filename = v.file or bufname,
      }
      -- non alphanumeric marks goes to last
      -- if mark:match("%w") then
      -- only capital marks
      if mark:match("[A-Z]") then
        -- capital and special marks
        -- if mark:match("[A-Z'\"\\[`^.<>]") or mark == "]" then
        table.insert(marks_table, row)
        -- else
        --     table.insert(marks_others, row)
      end
    end
  end

  function IndexOf(array, value)
    for i, v in ipairs(array) do
      if v == value then
        return i
      end
    end
    return nil
  end

  -- Sort the marks_table in a preferred mark_order.
  table.sort(marks_table, function(row_a, row_b)
    local mark_order = vim.g.presence_marks or { "J", "K", "L", "H", "G", "F", "D", "S", "A" }
    local mark_a = string.sub(row_a.line, 1, 1) -- get mark
    local mark_b = string.sub(row_b.line, 1, 1) -- get mark
    local index_a = IndexOf(mark_order, mark_a) or #mark_order
    local index_b = IndexOf(mark_order, mark_b) or #mark_order
    if index_a ~= #mark_order or index_b ~= #mark_order then
      return index_a < index_b
    else
      return mark_a < mark_b
    end
  end)
  -- marks_table = vim.fn.extend(marks_table, marks_others)

  pickers
    .new(opts, {
      prompt_title = "Marks",
      finder = finders.new_table({
        results = marks_table,
        entry_maker = opts.entry_maker or make_entry.gen_from_marks(opts),
      }),
      previewer = conf.grep_previewer(opts),
      sorter = conf.generic_sorter(opts),
      push_cursor_on_edit = true,
      push_tagstack_on_edit = true,
    })
    :find()
end

return telescope.register_extension({
  exports = {
    marks = list_marks,
  },
})
