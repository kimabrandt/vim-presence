local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local make_entry = require("telescope.make_entry")
local utils = require("telescope.utils")
local entry_display = require("telescope.pickers.entry_display")
local sorters = require("telescope.sorters")
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local strings = require("plenary.strings")
local path = require("plenary.path")

local conf = require("telescope.config").values

return function(opts)
  opts = opts or {}

  -- Get the list of session files.
  local session_dir = vim.fn.expand(opts.sessions_dir or "~/.vim/session")
  local session_files = vim.fn.split(vim.fn.globpath(session_dir, "*"), "\n")

  local sort = opts.sort or "mtime"
  if sort == "mtime" then
    -- Sort by last modification time (descending: newest first).
    table.sort(session_files, function(a, b)
      local mtime_a = path:new(a):_stat().mtime.sec
      local mtime_b = path:new(b):_stat().mtime.sec
      if mtime_a > mtime_b then -- descending mtime
        return true
      elseif mtime_a == mtime_b then -- equal mtime
        return a < b -- sort alphabetically
      else
        return false -- mtime_a < mtime_b
      end
    end)
  end

  local disable_devicons = opts.disable_devicons

  local icon_width = 0
  if not disable_devicons then
    local icon, _ = utils.get_devicons("fname", disable_devicons)
    icon_width = strings.strdisplaywidth(icon)
  end

  local displayer = entry_display.create({
    separator = " ",
    items = {
      { width = icon_width },
      { remaining = true },
    },
  })

  local make_display = function(entry)
    local display_bufname, path_style =
      utils.transform_path(opts, entry.filename)
    local icon, hl_group = utils.get_devicons(entry.filename, disable_devicons)

    return displayer({
      { icon, hl_group },
      {
        display_bufname,
        function()
          return path_style
        end,
      },
    })
  end

  local gen_from_files = function(options)
    return function(filename)
      return make_entry.set_default_entry_mt({
        value = filename,
        ordinal = filename,
        display = make_display,
        filename = filename,
      }, options)
    end
  end

  -- Create the picker.
  pickers
    .new(opts, {
      prompt_title = "Sessions",
      finder = finders.new_table({
        results = session_files,
        entry_maker = gen_from_files(opts),
      }),
      previewer = conf.grep_previewer(opts),
      sorter = sorters.get_fuzzy_file(),
      attach_mappings = function(prompt_bufnr)
        actions.select_default:replace(function()
          actions.close(prompt_bufnr)

          vim.schedule(function()
            -- Unload and delete all buffers.
            local success = vim.fn["presence#delete_all_buffers"]()
            if success == 1 then
              -- Load the session.
              local selection = action_state.get_selected_entry()
              if selection ~= nil then
                vim.cmd(
                  "silent! source " .. vim.fn.fnameescape(selection.value)
                )
              end
            end
          end)
        end)
        return true
      end,
    })
    :find()
end
