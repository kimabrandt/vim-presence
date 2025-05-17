" Supported global variables:
"
"   let g:presence_marks = "JKLHGFDSA"  " List of marks that should be used when saving, clearing and restoring them.
"   let g:presence_clear = 0            " Don't clear the marks - from the `g:presence_marks'-list - before restoring them.
"   let g:presence_clear = 1            " Clear the marks - from the `g:presence_marks'-list - before restoring them.

" Gets a list of supported global marks.
function s:get_global_marks() abort
  return split(get(g:, 'presence_marks', 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'), '\zs')
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
    call add(l:lines, 'delmarks ' . join(l:global_marks))
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

" Create an autocommand for saving the marks.
augroup presence_save
  autocmd!
  autocmd User Obsession call s:save_global_marks(g:this_session)
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

" Unloads and deletes buffers which don't have any global marks.
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

  call s:pause_obsession()
  call s:unload_and_delete_buffers(l:buffers)

  return 1
endfunction

" Adds a global mark and shifts back existing ones.
function presence#add_global_mark_and_shift_existing() abort
  " Supported global marks.
  let l:global_marks = s:get_global_marks()

  " For all marks, in reverse order.
  for i in range(len(l:global_marks) - 1, 0, -1)
    " Move the mark from the front to the back.
    call s:copy_mark(l:global_marks[i - 1], l:global_marks[i])
  endfor

  " Add the new mark, to the front.
  execute "normal! m" . l:global_marks[0]
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

  function! GetGlobalMarks() abort
    return s:get_global_marks()
  endfunction

  function! SaveGlobalMarks(session_file) abort
    call s:save_global_marks(a:session_file)
  endfunction

  function! CopyMark(old_mark, new_mark) abort
    call s:copy_mark(a:old_mark, a:new_mark)
  endfunction

  function! PauseObsession() abort
    call s:pause_obsession()
  endfunction

  function! UnloadAndDeleteBuffers(buffers) abort
    call s:unload_and_delete_buffers(a:buffers)
  endfunction
endif
