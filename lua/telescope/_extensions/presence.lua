local telescope = require("telescope")
local marks = require("telescope._extensions.presence.marks")
local sessions = require("telescope._extensions.presence.sessions")

return telescope.register_extension({
  exports = {
    marks = marks,
    sessions = sessions,
  },
})
