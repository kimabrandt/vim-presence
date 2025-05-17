local telescope = require("telescope")
local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local sorters = require("telescope.sorters")
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")

local function list_sessions(opts)
  opts = opts or {}

  -- Get the list of session files
  local session_dir = vim.fn.expand("~/.vim/session")
  local session_files = vim.fn.split(vim.fn.globpath(session_dir, "*"), "\n")

  -- Create the picker
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
      attach_mappings = function(prompt_bufnr, map)
        actions.select_default:replace(function()
          actions.close(prompt_bufnr)

          vim.schedule(function()
            -- Check the Obsession-variable
            local exists, _ = pcall(vim.api.nvim_get_var, "this_obsession")
            if exists then
              vim.cmd("silent! Obsession") -- Pause Obsession
            end

            local ok, err = pcall(function()
              -- Close all buffers
              vim.cmd("%bdelete")
            end)

            if ok then
              -- Load the session
              local selection = action_state.get_selected_entry()
              vim.cmd("silent! source " .. vim.fn.fnameescape(selection.value))
            elseif err then
              print(err)
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
