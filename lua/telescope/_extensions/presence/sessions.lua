local telescope = require("telescope")
local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local sorters = require("telescope.sorters")
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")

local function list_sessions(opts)
  opts = opts or {}

  -- Get the list of session files.
  local session_dir = vim.fn.expand(opts.sessions_dir or "~/.vim/session")
  local session_files = vim.fn.split(vim.fn.globpath(session_dir, "*"), "\n")

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
                vim.cmd("silent! source " .. vim.fn.fnameescape(selection.value))
              end
            end
          end)
        end)
        return true
      end,
    })
    :find()
end

return telescope.register_extension({
  exports = {
    sessions = list_sessions,
  },
})
