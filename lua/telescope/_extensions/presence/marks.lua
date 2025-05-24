local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local make_entry = require("telescope.make_entry")
local actions = require("telescope._extensions.presence.actions")
local utils = require("telescope.utils")
local strings = require("plenary.strings")
local entry_display = require("telescope.pickers.entry_display")

local conf = require("telescope.config").values

return function(opts)
  opts = opts or {}

  if opts.bufnr == nil then
    opts.bufnr = vim.api.nvim_get_current_buf()
  end

  local max_lnum = 1
  local max_col = 1
  local marks_table = {}
  for _, v in ipairs(vim.fn.getmarklist()) do
    -- strip the first single quote character
    local mark = string.sub(v.mark, 2, 3)
    -- only capital marks
    if mark:match("[A-Z]") then
      local _, lnum, col, _ = unpack(v.pos)
      local row = {
        line = string.format("%s %6d %4d %s", mark, lnum, col - 1, v.file),
        mark = mark,
        lnum = lnum,
        col = col,
        filename = v.file,
      }
      table.insert(marks_table, row)
      if lnum > max_lnum then
        max_lnum = lnum
      end
      if col > max_col then
        max_col = col
      end
    end
  end

  local get_marks_order = function()
    local mark_list = opts.marks
      or vim.g.presence_marks
      or "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    local marks = {}
    for mark in mark_list:gmatch(".") do
      table.insert(marks, mark)
    end
    return marks
  end

  local index_of = function(array, value)
    for i, v in ipairs(array) do
      if v == value then
        return i
      end
    end
    return nil
  end

  -- Sort the marks_table in a preferred mark_order.
  table.sort(marks_table, function(row_a, row_b)
    local mark_order = get_marks_order()
    local mark_a = row_a.mark
    local mark_b = row_b.mark
    local index_a = index_of(mark_order, mark_a) or #mark_order + 1
    local index_b = index_of(mark_order, mark_b) or #mark_order + 1
    if index_a ~= #mark_order or index_b ~= #mark_order then
      return index_a < index_b
    else
      return mark_a < mark_b
    end
  end)

  local disable_devicons = opts.disable_devicons

  local icon_width = 0
  if not disable_devicons then
    local icon, _ = utils.get_devicons("fname", disable_devicons)
    icon_width = strings.strdisplaywidth(icon)
  end

  local max_lnum_width = #tostring(max_lnum)
  local col_width = #tostring(max_col)
  local displayer = entry_display.create({
    separator = " ",
    items = {
      { width = 1 }, -- mark width
      { width = max_lnum_width + 1 + col_width }, -- "lnum:col"
      { width = icon_width },
      { remaining = true },
    },
  })

  local make_display = function(entry)
    local display_bufname, path_style =
      utils.transform_path(opts, entry.filename)
    local icon, hl_group = utils.get_devicons(entry.filename, disable_devicons)

    local lnum_pad = string.rep(" ", max_lnum_width - #tostring(entry.lnum))

    return displayer({
      { entry.mark, "TelescopeResultsIdentifier" },
      { lnum_pad .. entry.lnum .. ":" .. entry.col, "TelescopeResultsLineNr" },
      { icon, hl_group },
      {
        display_bufname,
        function()
          return path_style
        end,
      },
    })
  end

  local gen_from_marks = function(opts)
    return function(item)
      return make_entry.set_default_entry_mt({
        value = item.line,
        ordinal = item.line,
        display = make_display,
        mark = item.mark,
        lnum = item.lnum,
        col = item.col,
        filename = item.filename,
      }, opts)
    end
  end

  pickers
    .new(opts, {
      prompt_title = "Marks",
      finder = finders.new_table({
        results = marks_table,
        entry_maker = gen_from_marks(opts),
      }),
      previewer = conf.grep_previewer(opts),
      attach_mappings = function(_, map)
        map("i", "<c-d>", actions.delete_mark_selections)
        map("n", "<c-d>", actions.delete_mark_selections)
        return true
      end,
      sorter = conf.generic_sorter(opts),
      push_cursor_on_edit = true,
      push_tagstack_on_edit = true,
    })
    :find()
end
