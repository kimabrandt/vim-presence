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

    -- Reset test-environment.
    vim.cmd([[
      delmarks A-Z " delete global marks
      let g:test_mode = 1 " enable test-mode (export functions)
      source plugin/presence.vim " load the plugin
      call TestResetGlobalMarks() " reset global marks
    ]])
  end)

  it("should return supported global marks", function()
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
      let g:presence_marks = "JKLHGFDSA" " set home row marks
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

  it("should return tracked global marks", function()
    -- Test the tracked marks.
    local marks = vim.fn.TestGetTrackedMarks()
    assert.are_equal(0, #marks, "marks should be 0 items")
    assert.are_equal("", table.concat(marks, ""), "marks should be empty")
  end)

  it("should only return tracked marks", function()
    vim.cmd([[
      let g:presence_tracked = "JKL" " set tracked marks
    ]])

    -- Test the tracked marks.
    local marks = vim.fn.TestGetTrackedMarks()
    assert.are_equal(3, #marks, "marks should only be 3 items")
    assert.are_equal(
      "JKL",
      table.concat(marks, ""),
      "marks should be equal to g:presence_tracked"
    )
  end)

  it("should save and restore global marks", function()
    vim.cmd([[
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

  it("should track global marks", function()
    vim.cmd([[
      let g:presence_tracked = "JKL" " set tracked marks
      let s:lines = []
      call add(s:lines, 'first line')
      call add(s:lines, 'second line')
      call writefile(s:lines, '/tmp/presence_test/Test_y0xm.txt') " create a test-file
      edit /tmp/presence_test/Test_y0xm.txt
      call setpos("'J", [0, 1, 10, 0]) " set the position for mark J
      call setpos(".", [0, 2, 6, 0]) " move the cursor position
      call TestTrackGlobalMarks() " track global marks
    ]])

    -- Test the position for mark J.
    local pos = vim.fn.getpos("'J")
    assert.are_equal(2, pos[2], "row should be 2")
    assert.are_equal(6, pos[3], "column should be 6")
  end)

  it("should trigger the augroup presence_save and save the session", function()
    vim.cmd([[
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

  it("should trigger the augroup presence_track and track the mark", function()
    vim.cmd([[
      let g:presence_tracked = "JKL" " set tracked marks
      let s:lines = []
      call add(s:lines, 'first line')
      call add(s:lines, 'second line')
      call writefile(s:lines, '/tmp/presence_test/Test_6zwg.txt') " create a test-file
      edit /tmp/presence_test/Test_6zwg.txt
      call setpos("'J", [0, 1, 2, 0]) " create mark
      call setpos(".", [0, 2, 9, 0]) " move the cursor position
      doautocmd <nomodeline> presence_track BufLeave " trigger autocommand
    ]])

    -- Test the position for mark J.
    local pos = vim.fn.getpos("'J")
    assert.are_equal(2, pos[2], "row should be 2")
    assert.are_equal(9, pos[3], "column should be 9")
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
      let g:presence_marks = "JKL"
      call presence#add_global_mark_and_shift_backward()
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
    vim.fn["presence#add_global_mark_and_shift_backward"]() -- add the mark

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

  it("should remove gaps in marks list", function()
    vim.cmd([[
      let g:presence_marks = "JKLHGFDSA" " set home row marks
      let lines = []
      call add(lines, 'first line')
      call add(lines, 'second line')
      call writefile(lines, '/tmp/presence_test/Test_5dhx.txt') " create a test-file
      edit /tmp/presence_test/Test_5dhx.txt
      call setpos("'J", [0, 1, 1, 0]) " stays 'J
      call setpos("'G", [0, 1, 2, 0]) " should become 'K
      call setpos("'A", [0, 1, 3, 0]) " should become 'L
      call setpos("'N", [0, 1, 4, 0]) " stays 'N
      call setpos("'U", [0, 1, 5, 0]) " stays 'U
      call presence#remove_gaps_in_marks_list()
    ]])

    -- Test the position for mark J, before adding.
    local pos = vim.fn.getpos("'J")
    assert.are_equal(1, pos[2], "row should be 1")
    assert.are_equal(1, pos[3], "column should be 1")

    -- Test the position for mark K (newly added).
    pos = vim.fn.getpos("'K")
    assert.are_equal(1, pos[2], "row should be 1")
    assert.are_equal(2, pos[3], "column should be 2")

    -- Test the position for mark L (newly added).
    pos = vim.fn.getpos("'L")
    assert.are_equal(1, pos[2], "row should be 1")
    assert.are_equal(3, pos[3], "column should be 3")

    -- Test the position for mark N (newly added).
    pos = vim.fn.getpos("'N")
    assert.are_equal(1, pos[2], "row should be 1")
    assert.are_equal(4, pos[3], "column should be 4")

    -- Test the position for mark U (newly added).
    pos = vim.fn.getpos("'U")
    assert.are_equal(1, pos[2], "row should be 1")
    assert.are_equal(5, pos[3], "column should be 5")
  end)

  -- -- TODO test function presence#add_global_mark_to_the_end_and_replace_last()
  -- -- TODO test function presence#delete_global_mark_and_shift_forward()
end)
