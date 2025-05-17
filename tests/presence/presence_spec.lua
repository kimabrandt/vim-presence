-- Testing from inside Neovim:
--
--     :PlenaryBustedFile %
--
-- Testing from the terminal:
--
--     $ make test

describe("presence.nvim", function()
  before_each(function()
    -- Create the test-directory.
    os.execute("mkdir -p /tmp/presence_test")
  end)

  it("should return supported global marks", function()
    vim.cmd([[
      let g:test_mode = 1 " enable test-mode (export functions)
      source plugin/presence.vim " load the plugin
    ]])

    -- Test the global marks.
    local marks = vim.fn.TestGetGlobalMarks()
    assert.are_equal(26, #marks, "marks should be 26 items")
    assert.are_equal(
      "ABCDEFGHIJKLMNOPQRSTUVWXYZ",
      table.concat(marks, ""),
      "marks should be from A to Z"
    )
  end)

  it("should only return home row global marks", function()
    vim.cmd([[
      let g:test_mode = 1 " enable test-mode (export functions)
      let g:presence_marks = "JKLHGFDSA" " set home row marks
      source plugin/presence.vim " load the plugin
    ]])

    -- Test the home row global marks.
    local marks = vim.fn.TestGetGlobalMarks()
    assert.are_equal(9, #marks, "marks should only be 9 items")
    assert.are_equal(
      "JKLHGFDSA",
      table.concat(marks, ""),
      "marks should only be from the home row"
    )
  end)

  it("should save and restore global marks", function()
    vim.cmd([[
      let g:test_mode = 1 " enable test-mode (export functions)
      source plugin/presence.vim " load the plugin
      mksession! /tmp/presence_test/Session_02b9.vim
      let s:lines = []
      call add(s:lines, 'first line')
      call add(s:lines, 'second line')
      call writefile(s:lines, '/tmp/presence_test/Test_e094.txt') " create a test-file
      edit /tmp/presence_test/Test_e094.txt
      call setpos("'J", [0, 1, 7, 0]) " set the position for mark J
      call TestSaveGlobalMarks("/tmp/presence_test/Session_02b9.vim") " save global marks
      call setpos("'J", [0, 2, 8, 0]) " override the position for mark J
      source /tmp/presence_test/Session_02b9.vim " restore the session
    ]])

    -- Test the position for mark J.
    local pos = vim.fn.getpos("'J")
    assert.are_equal(1, pos[2], "row should be 1")
    assert.are_equal(7, pos[3], "column should be 7")
  end)

  it("should trigger the autocommand and save the session", function()
    vim.cmd([[
      let g:test_mode = 1 " enable test-mode (export functions)
      source plugin/presence.vim " load the plugin
      let s:lines = []
      call add(s:lines, 'first line')
      call add(s:lines, 'second line')
      call writefile(s:lines, '/tmp/presence_test/Test_ba9b.txt') " create a test-file
      edit /tmp/presence_test/Test_ba9b.txt
      call setpos("'J", [0, 1, 5, 0]) " create mark
      mksession! /tmp/presence_test/Session_c13b.vim " make a session
      let g:this_session = '/tmp/presence_test/Session_c13b.vim' " set the session-file
      doautocmd <nomodeline> User Obsession " trigger obsession-autocommand
      call setpos("'J", [0, 2, 6, 0]) " override the position for mark J
      source /tmp/presence_test/Session_c13b.vim " restore the session
    ]])

    -- Test the position for mark J.
    local pos = vim.fn.getpos("'J")
    assert.are_equal(1, pos[2], "row should be 1")
    assert.are_equal(5, pos[3], "column should be 5")
  end)

  it("should pause obsessions session-tracking", function()
    vim.api.nvim_create_user_command("Obsession", function()
      vim.g.this_obsession = nil
    end, {})
    vim.g.this_obsession = "/tmp/presence_test/Test_fcba.txt"
    vim.fn.TestPauseObsession()
    assert.are_equal(
      nil,
      vim.g.this_obsession,
      "this_obsession should be blank"
    )
  end)

  it("should unload and delete all buffers", function()
    vim.cmd([[
      edit /tmp/presence_test/Test_6395.txt
      edit /tmp/presence_test/Test_a8f9.txt
      edit /tmp/presence_test/Test_4b91.txt
    ]])

    -- Unload and delete all buffers.
    vim.fn.TestUnloadAndDeleteBuffers(vim.api.nvim_list_bufs())

    -- Test if the buffers were unloaded.
    assert.are_equal(0, vim.fn.bufloaded("/tmp/presence_test/Test_6395.txt"))
    assert.are_equal(0, vim.fn.bufloaded("/tmp/presence_test/Test_a8f9.txt"))
    assert.are_equal(0, vim.fn.bufloaded("/tmp/presence_test/Test_4b91.txt"))
  end)

  it("should unload and delete the given buffers", function()
    vim.cmd([[
      edit /tmp/presence_test/Test_99f6.txt
      edit /tmp/presence_test/Test_4eca.txt
      edit /tmp/presence_test/Test_64cf.txt
    ]])

    -- Unload and delete the given buffers.
    vim.fn.TestUnloadAndDeleteBuffers({
      vim.fn.bufnr("/tmp/presence_test/Test_4eca.txt"),
      vim.fn.bufnr("/tmp/presence_test/Test_64cf.txt"),
    })

    -- Test if the buffers were unloaded.
    assert.are_equal(0, vim.fn.bufloaded("/tmp/presence_test/Test_4eca.txt"))
    assert.are_equal(0, vim.fn.bufloaded("/tmp/presence_test/Test_64cf.txt"))

    -- Test if the other buffer is still loaded.
    assert.are_equal(1, vim.fn.bufloaded("/tmp/presence_test/Test_99f6.txt"))
  end)

  it("should copy a global mark", function()
    vim.cmd([[
      let g:test_mode = 1 " enable test-mode (export functions)
      source plugin/presence.vim " load the plugin
      call setpos("'J", [0, 2, 8, 0]) " set the position for mark J
      call setpos("'K", [0, 0, 0, 0]) " set the position for mark K
    ]])

    -- Test the position for mark J.
    local pos = vim.fn.getpos("'J")
    assert.are_equal(2, pos[2], "row should be 2")
    assert.are_equal(8, pos[3], "column should be 8")

    -- Test the position for mark K, before copying.
    pos = vim.fn.getpos("'K")
    assert.are_equal(0, pos[2], "row should be 0")
    assert.are_equal(0, pos[3], "column should be 0")

    -- Copy the mark J to K.
    vim.fn.TestCopyMark("J", "K")

    -- Test the position for mark K, after copying.
    pos = vim.fn.getpos("'K")
    assert.are_equal(2, pos[2], "row should be 2")
    assert.are_equal(8, pos[3], "column should be 8")
  end)

  it("should add a new mark to the list of supported global marks", function()
    vim.cmd([[
      let g:test_mode = 1 " enable test-mode (export functions)
      let g:presence_marks = "JKL"
      source plugin/presence.vim " load the plugin
      call presence#add_global_mark_and_shift_existing()
      let lines = []
      call add(lines, 'first line')
      call add(lines, 'second line')
      call writefile(lines, '/tmp/presence_test/Test_4b8f.txt') " create a test-file
      edit /tmp/presence_test/Test_4b8f.txt
      call setpos("'J", [0, 1, 1, 0])
      call setpos("'K", [0, 2, 1, 0])
      call setpos("'L", [0, 2, 8, 0])
    ]])

    -- Test the position for mark J, before adding.
    local pos = vim.fn.getpos("'J")
    assert.are_equal(1, pos[2], "row should be 1")
    assert.are_equal(1, pos[3], "column should be 1")

    -- Test the position for mark K, before adding.
    pos = vim.fn.getpos("'K")
    assert.are_equal(2, pos[2], "row should be 2")
    assert.are_equal(1, pos[3], "column should be 1")

    -- Test the position for mark L, before adding.
    pos = vim.fn.getpos("'L")
    assert.are_equal(2, pos[2], "row should be 2")
    assert.are_equal(8, pos[3], "column should be 8")

    -- Add a new mark.
    vim.fn.setpos(".", { 0, 1, 7, 0 }) -- set the cursor position
    vim.fn["presence#add_global_mark_and_shift_existing"]() -- add the mark

    -- Test the position for mark J (newly added).
    pos = vim.fn.getpos("'J")
    assert.are_equal(1, pos[2], "row should be 1")
    assert.are_equal(7, pos[3], "column should be 7")

    -- Test the position for mark K (previously mark J), after adding.
    pos = vim.fn.getpos("'K")
    assert.are_equal(1, pos[2], "row should be 1")
    assert.are_equal(1, pos[3], "column should be 1")

    -- Test the position for mark L (previously mark K), after adding.
    pos = vim.fn.getpos("'L")
    assert.are_equal(2, pos[2], "row should be 2")
    assert.are_equal(1, pos[3], "column should be 1")
  end)

  it("should delete buffers without global marks", function()
    vim.cmd([[
      let g:test_mode = 1 " enable test-mode (export functions)
      source plugin/presence.vim " load the plugin
      edit /tmp/presence_test/Test_7cf4_close.txt
      edit /tmp/presence_test/Test_ea15_keep.txt
      call setpos("'J", [0, 1, 1, 0]) " create mark
      call presence#delete_buffers_without_global_marks()
    ]])

    -- Test if the buffer was unloaded.
    local bufloaded = vim.fn.bufloaded("/tmp/presence_test/Test_7cf4_close.txt")
    assert.are_equal(0, bufloaded, "buffer should be unloaded")

    -- Test if the buffer is still loaded.
    bufloaded = vim.fn.bufloaded("/tmp/presence_test/Test_ea15_keep.txt")
    assert.are_equal(1, bufloaded, "buffer should be loaded")
  end)

  it("should delete all buffers, even those with global marks", function()
    vim.cmd([[
      let g:test_mode = 1 " enable test-mode (export functions)
      source plugin/presence.vim " load the plugin
      edit /tmp/presence_test/Test_24fe.txt
      call setpos("'J", [0, 1, 1, 0]) " create mark
      edit /tmp/presence_test/Test_ec77.txt
      call setpos("'K", [0, 1, 1, 0]) " create mark
      edit /tmp/presence_test/Test_efe8.txt
      call presence#delete_all_buffers()
    ]])

    -- Test if the buffers were unloaded.
    assert.are_equal(
      0,
      vim.fn.bufloaded("/tmp/presence_test/Test_24fe.txt"),
      "buffer should be unloaded"
    )
    assert.are_equal(
      0,
      vim.fn.bufloaded("/tmp/presence_test/Test_ec77.txt"),
      "buffer should be unloaded"
    )
    assert.are_equal(
      0,
      vim.fn.bufloaded("/tmp/presence_test/Test_efe8.txt"),
      "buffer should be unloaded"
    )
  end)
end)
