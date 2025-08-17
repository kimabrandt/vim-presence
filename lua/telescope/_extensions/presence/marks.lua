local pickers = require("telescope.pickers")
local finders = require("telescope._extensions.presence.finders")

local conf = require("telescope.config").values

return function(opts)
  opts = opts or {}

  if opts.bufnr == nil then
    opts.bufnr = vim.api.nvim_get_current_buf()
  end

  pickers
    .new(opts, {
      prompt_title = "Marks",
      finder = finders.build_finder(opts),
      previewer = conf.grep_previewer(opts),
      sorter = conf.generic_sorter(opts),
    })
    :find()
end
