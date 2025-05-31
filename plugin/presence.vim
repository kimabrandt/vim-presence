" Supported global variables:
"
"   let g:presence_marks = "JKLHGFDSA"                   " List of marks that should be saved, cleared and restored.
"   let g:presence_marks = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"  " The default.
"
"   let g:presence_tracked = "JKLH"  " List of marks that should be tracked.
"   let g:presence_tracked = ""      " The default.
"
"   let g:presence_clear = 0  " Don't clear existing marks, before restoring them.
"   let g:presence_clear = 1  " The default. Clear existing marks, before restoring them.

" Gets a list of supported global marks.
function s:get_global_marks() abort
  return split(get(g:, 'presence_marks', 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'), '\zs')
endfunction

" Gets a list of tracked global marks.
function s:get_tracked_marks() abort
  return split(get(g:, 'presence_tracked', ''), '\zs')
endfunction

" Saves global marks to the session-file.
function s:save_global_marks(session_file) abort
  " Supported global marks.
  let l:global_marks = s:get_global_marks()

  " Files with marks.
  let l:files = {}

  " For all global marks.
  for l:marks in getmarklist()
    " Remove the "'"-prefix from the name of the mark.
    let l:mark = substitute(l:marks.mark, "'", "", "")

    " Check if the mark is supported.
    if index(l:global_marks, l:mark) == -1
      " Ignore the mark.
      continue
    endif

    let l:file = l:marks.file
    let l:pos = l:marks.pos
    let l:lnum = l:pos[1]
    let l:column = l:pos[2]

    " Check if the file was already discovered.
    if has_key(l:files, l:file)
      " Use existing list of marks, from an already discovered marked file.
      let l:list = l:files[l:file]
    else
      " Create a new list of marks, for a newly discovered marked file.
      let l:list = []
      let l:files[l:file] = l:list

      " Determines the buffer number, when the session-file is loaded.
      call add(l:list, "let s:bufnum = bufnr(fnamemodify(\"" . fnameescape(l:file) . "\", \":p\"), 1)")
    endif

    " Restores the position for the mark, when the session-file is loaded.
    call add(l:list, "call setpos(\"'" . l:mark . "\", [s:bufnum, " . l:lnum . ", " . l:column . ", 0])")
  endfor

  " Lines that should be stored in the session-file.
  let l:lines = []

  " Check if marks should be cleared, before restoring them.
  if exists('g:presence_clear') == 0 || get(g:, 'presence_clear', 1)
    " Clears the marks, when the session-file is loaded.
    call add(l:lines, 'delmarks ' . join(l:global_marks, ''))
  endif

  " Prepare the lines.
  for l:list in values(l:files)
    call add(l:lines, l:list)
  endfor

  " Read the session-file.
  let l:body = readfile(a:session_file)

  " Find the index, where to add the lines inside the session-file.
  let l:idx = 0
  for l:i in range(0, len(l:body) - 1)
    " Find the `shortmess` if-else-block.
    if match(l:body[l:i], "if &shortmess =\\~ 'A'") == 0
      " Set the index, right after the if-else-block.
      let l:idx = l:i + 5
      break
    endif
  endfor

  " Insert the lines at the index.
  for l:line in reverse(flatten(l:lines))
    call insert(l:body, l:line, l:idx)
  endfor

  " Write the session-file.
  call writefile(l:body, a:session_file)
endfunction

" " Keeps track of last tracked.
" let s:last_tracked = reltime()

" Tracks global marks.
function s:track_global_marks() abort
  " " Time in milliseconds
  " let l:now = reltime()
  " let l:elapsed = reltimefloat(reltime(s:last_tracked)) * 1000
  " if l:elapsed < 100
  "   return
  " endif
  "
  " " Update when last tracked.
  " let s:last_tracked = l:now

  " Tracked global marks.
  let l:tracked_marks = s:get_tracked_marks()

  " Get the current file.
  let l:current_file = expand('%:p')

  " For all tracked marks.
  for l:mark in l:tracked_marks
    " Get the mark position.
    let l:pos = getpos("'" . l:mark)
    " Get the markfile.
    let l:markfile = fnamemodify(bufname(l:pos[0]), ':p')
    " If the markfile is the same as the current_file.
    if fnamemodify(l:markfile, ':p') ==# l:current_file
      " Set the mark at the current location.
      execute "normal! m" . l:mark
      return
    endif
  endfor
endfunction

" Create an autocommand for saving marks.
augroup presence_save
  autocmd!
  autocmd User Obsession call s:save_global_marks(g:this_session)
  " autocmd User Obsession call s:track_global_marks() | call s:save_global_marks(g:this_session)
augroup END

" Create an autocommand for tracking marks.
augroup presence_track
  autocmd!
  autocmd BufLeave * call s:track_global_marks()
  " autocmd BufUnload * call s:track_global_marks()
  autocmd VimLeavePre * call s:track_global_marks()
augroup END

" Pauses obsessions session-tracking.
function s:pause_obsession() abort
  if exists("g:this_obsession")
    silent! Obsession
  endif
endfunction

" Unloads and deletes the passed in buffers.
function s:unload_and_delete_buffers(buffers) abort
  for l:buffer in a:buffers
    if buflisted(l:buffer)
      execute 'bdelete ' . l:buffer
    endif
  endfor
endfunction

" Shows an error.
function s:show_error(message) abort
  echohl ErrorMsg
  echo a:message
  echohl None
endfunction

" Checks if the buffer has unsaved changes.
function s:buffer_was_modified(buffer) abort
  return getbufvar(a:buffer, '&modified')
endfunction

" Edits the buffer, and thereby puts it into focus.
function s:edit_and_show_buffer(buffer) abort
  execute 'buffer ' . a:buffer
endfunction

" Checks if the buffer has one of the marks.
function s:buffer_has_marks(buffer, marks) abort
  " For all supported marks.
  for l:mark in a:marks
    " Get the position of the mark.
    let pos = getpos("'" . l:mark)

    " Check if the mark points to the buffer.
    if pos[0] == a:buffer
      return 1
    endif
  endfor

  return 0
endfunction

" Unloads and deletes all buffers.
function presence#delete_all_buffers() abort
  " List of buffers without marks.
  let l:buffers = []

  " For all opened buffers.
  for l:buffer in range(1, bufnr('$'))
    if s:buffer_was_modified(l:buffer)
      call s:edit_and_show_buffer(l:buffer)
      call s:show_error('The buffer has unsaved changes')
      return 0
    endif

    if buflisted(l:buffer)
      " Add the buffer to the list.
      call add(l:buffers, l:buffer)
    endif
  endfor

  call s:pause_obsession()
  call s:unload_and_delete_buffers(l:buffers)

  return 1
endfunction

" Unloads and deletes buffers without global marks.
function presence#delete_buffers_without_global_marks() abort
  " Supported global marks.
  let l:global_marks = s:get_global_marks()

  " List of buffers without marks.
  let l:buffers = []

  " For all opened buffers.
  for l:buffer in range(1, bufnr('$'))
    if buflisted(l:buffer)
      if !s:buffer_has_marks(l:buffer, l:global_marks)
        if s:buffer_was_modified(l:buffer)
          call s:edit_and_show_buffer(l:buffer)
          call s:show_error('The buffer has unsaved changes')
          return 0
        endif

        " Add the buffer to the list.
        call add(l:buffers, l:buffer)
      endif
    endif
  endfor

  call s:unload_and_delete_buffers(l:buffers)

  return 1
endfunction

function GlobalMarkExists(mark)
  for l:m in getmarklist()
    if l:m.mark == "'" . a:mark
      return 1
    endif
  endfor
  return 0
endfunction

function presence#remove_gaps_in_marks_list() abort
  " Supported global marks.
  let l:global_marks = s:get_global_marks()

  let l:marks = []

  " Collect existing marks.
  for l:i in range(0, len(l:global_marks) - 1)
    let l:mark = l:global_marks[l:i]
    " Check if the global mark exists.
    if GlobalMarkExists(l:mark) == 1
      " Add the mark to the list.
      call add(l:marks, l:mark)
    endif
  endfor

  " For every supported mark.
  for l:i in range(0, len(l:global_marks) - 1)
    let l:new_mark = l:global_marks[l:i]
    " Check for more marks.
    if len(l:marks) > l:i
      let l:old_mark = l:marks[l:i]
      " Copy the mark and thereby removing the gap.
      call s:copy_mark(l:old_mark, l:new_mark)
    else
      " Remove leftover marks.
      execute "delmarks " . l:new_mark
    endif
  endfor
endfunction

" Adds a global mark and shifts backward existing ones.
function presence#add_global_mark_and_shift_backward() abort
  " Supported global marks.
  let l:global_marks = s:get_global_marks()

  " For all marks, in reverse order.
  for l:i in range(len(l:global_marks) - 1, 0, -1)
    " Move the mark from the front to the back.
    call s:copy_mark(l:global_marks[l:i - 1], l:global_marks[l:i])
  endfor

  " Add the new mark, to the front.
  execute "normal! m" . l:global_marks[0]
endfunction

" Adds a global mark to the end and potentially replaces the last one.
function presence#add_global_mark_to_the_end_and_replace_last() abort
  " Supported global marks.
  let l:global_marks = s:get_global_marks()

  " Point the index on the last mark.
  let l:index = len(l:global_marks) - 1

  " For all marks, in reverse order.
  for l:i in range(len(l:global_marks) - 1, 0, -1)
    let l:mark = l:global_marks[l:i]
    " Check if the global mark exists.
    if GlobalMarkExists(l:mark) == 1
      " Found the last mark.
      break
    else
      " Remember the index.
      let l:index = l:i
    endif
  endfor

  " Add the new mark, to the end.
  execute "normal! m" . l:global_marks[l:index]
endfunction

" Deletes a global mark and shifts forward the rest
function presence#delete_global_mark_and_shift_forward() abort
  " Supported global marks.
  let l:global_marks = s:get_global_marks()

  " let l:marks_length = len(l:global_marks)

  " Delete the first mark.
  execute "delmarks " . l:global_marks[0]

  " Shift the rest forward.
  for l:i in range(1, len(l:global_marks) - 1)
    call s:copy_mark(l:global_marks[l:i], l:global_marks[l:i - 1])
    execute "delmarks " . l:global_marks[l:i]
  endfor
endfunction

" Copies the position from one mark to another.
function s:copy_mark(old_mark, new_mark)
  " Get the position of the old mark.
  let old_pos = getpos("'" . a:old_mark)

  " Check if the position has a valid line number.
  if old_pos[1] > 0
    " Set the position for the new mark.
    call setpos("'" . a:new_mark, old_pos)
  endif
endfunction

if exists('g:test_mode')
  " Export functions for testing.

  function! TestResetGlobalMarks() abort
    " let s:last_tracked = [0, 0] " allow tracking to trigger

    " Unlet global variables.
    if exists("g:presence_marks")
      unlet g:presence_marks
    endif
    if exists("g:presence_tracked")
      unlet g:presence_tracked
    endif
    if exists("g:presence_clear")
      unlet g:presence_clear
    endif
  endfunction

  function! TestGetGlobalMarks() abort
    return s:get_global_marks()
  endfunction

  function! TestGetTrackedMarks() abort
    return s:get_tracked_marks()
  endfunction

  function! TestSaveGlobalMarks(session_file) abort
    call s:save_global_marks(a:session_file)
  endfunction

  function! TestTrackGlobalMarks() abort
    call s:track_global_marks()
  endfunction

  function! TestCopyMark(old_mark, new_mark) abort
    call s:copy_mark(a:old_mark, a:new_mark)
  endfunction

  function! TestPauseObsession() abort
    call s:pause_obsession()
  endfunction

  function! TestUnloadAndDeleteBuffers(buffers) abort
    call s:unload_and_delete_buffers(a:buffers)
  endfunction
endif
