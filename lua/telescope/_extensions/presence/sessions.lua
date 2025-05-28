local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local sorters = require("telescope.sorters")
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local path = require("plenary.path")

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

  -- Create the picker.
  pickers
    .new(opts, {
      prompt_title = "Sessions",
      finder = finders.new_table({
        results = session_files,
        entry_maker = function(entry)
          return {
            display = vim.fn.fnamemodify(entry, ":t"),
            ordinal = entry,
            value = entry,
          }
        end,
      }),
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
