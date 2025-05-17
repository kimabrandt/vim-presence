" Save global marks to the obsession-file.
function! s:save_global_marks() abort
  let l:marked_files = {}
  let l:ordered_files = []
  for l:mark_item in getmarklist()
    let l:mark = l:mark_item.mark
    if l:mark !~# "^'[A-Z]$"
      " ignore non-global marks
      continue
    else
      " remove the "'"-prefix from the mark
      let l:mark = substitute(l:mark, "'", "", "")
    endif

    let l:file = l:mark_item.file
    let l:pos = l:mark_item.pos
    let l:lnum = l:pos[1]
    let l:column = l:pos[2]

    if has_key(l:marked_files, l:file)
      " use existing list of marks, from an already discovered marked file
      let l:list = l:marked_files[l:file]
    else
      " create a new list of marks, for a newly discovered marked file
      let l:list = []
      let l:marked_files[l:file] = l:list
      call add(l:list, "badd +" . l:lnum . " " . fnameescape(l:file)) " add file to buffer-list
      call add(l:list, "keepjumps buffer " . fnameescape(l:file)) " edit file
      call add(l:ordered_files, l:file) " keep order of discovered files
    endif
    call add(l:list, "call setcursorcharpos(" . l:lnum . ", " . l:column . ")") " go to cursor position
    call add(l:list, "normal! m" . l:mark) " set mark
  endfor

  let l:lines = []
  call add(l:lines, "delmarks A-Z") " delete marks in the range A to Z
  for l:file in l:ordered_files
    let l:list = l:marked_files[l:file]
    call add(l:lines, l:list)
    let l:bufnr = bufnr(l:file)
    if bufloaded(l:bufnr)
      let l:lnum = getbufinfo(l:bufnr)[0]['lnum']
      call add(l:list, l:lnum) " go to line, preempt `badd`
    endif
  endfor

  let l:body = readfile(g:this_obsession)
  let l:idx = 0
  for l:i in range(0, len(l:body) - 1)
    if match(l:body[l:i], "if &shortmess =\\~ 'A'") == 0
      let l:idx = l:i + 5 " place after the `shortmess` if-else-block
      break
    endif
  endfor
  for l:line in reverse(flatten(l:lines))
    call insert(l:body, l:line, l:idx)
  endfor
  call writefile(l:body, g:this_obsession)
endfunction

augroup my_obsession
  autocmd!
  autocmd User Obsession call s:save_global_marks()
augroup END



" Delete buffers that don't have any marks.
function! s:delete_buffers_without_marks() abort
  " List to hold buffers without marks
  let no_mark_buffers = []

  " Loop over all buffers
  for buf in range(1, bufnr('$'))
    " Check if buffer exists
    if buflisted(buf)
      " Assume no marks initially
      let has_marks = 0

      " Check each mark from 'A' to 'Z'
      for mark in range(char2nr('A'), char2nr('Z'))
        " Get mark position
        let pos = getpos("'" . nr2char(mark))
        " Check if the mark is in this buffer
        if pos[0] == buf
          let has_marks = 1
          break
        endif
      endfor

      " If no marks found, add to list
      if has_marks == 0
        call add(no_mark_buffers, buf)
      endif
    endif
  endfor

  " Close all buffers collected
  for buf in no_mark_buffers
    " Check if the buffer has unsaved changes
    if getbufvar(buf, '&modified')
      " Edit the buffer
      execute 'buffer ' . buf
    endif

    " Use bdelete to close buffers safely
    execute 'bdelete ' . buf
  endfor
endfunction

command! -bar -bang -complete=file -nargs=? DeleteBuffersWithoutMarks
      \ call s:delete_buffers_without_marks()



" Add a mark at the beginning of the list of `g:presence_marks` and shift the
" existing ones.
function! AddMark() abort
  " Define the list of marks to use
  let marks = get(g:, 'presence_marks', ["J", "K", "L", "H", "G", "F", "D", "S", "A"]) " default to home row keys

  " Iterate through the marks in reverse order to shift them back
  for i in range(len(marks) - 1, 0, -1)
    " Move the previous mark to the next
    call s:move_mark(marks[i - 1], marks[i])
  endfor

  " Set the new mark at the current location for the first mark
  execute "normal! m" . marks[0]
endfunction

" Function to copy the position of one mark to another
function! s:move_mark(old_mark, new_mark)
  " Get the position of the old mark
  let old_pos = getpos("'" . a:old_mark)
  if old_pos[1] > 0
    " Set the old mark's position for the new mark
    call setpos("'" . a:new_mark, old_pos)
  endif
endfunction



" Jumps to the specified mark.
function! JumpToMark(mark)
  " Get the buffer number associated with the mark
  let l:marks = filter(getmarklist(), {_, mark -> mark['mark'] == "'" . a:mark})
  if len(marks) == 0
    return
  endif

  let l:mark_item = marks[0]
  let l:file = l:mark_item.file
  let l:pos = l:mark_item.pos
  let l:lnum = l:pos[1]
  let l:column = l:pos[2]
  let l:buffer = bufnr(file)

  " Get the range of the current view
  let l:first_visible_line = line("w0")
  let l:last_visible_line = line("w$")

  let l:is_before_view = l:lnum < l:first_visible_line
  let l:is_after_view = l:lnum > l:last_visible_line
  let l:is_outside_buffer = l:buffer != bufnr('%')

  " Check if the mark is within the current view range, or if the cursor is on the first line
  if l:is_before_view || l:is_after_view || l:is_outside_buffer
    " The mark is outside the current view
    " Jump to the mark
    execute "normal! `" . a:mark
  else
    " The mark is inside the current view
    call setcursorcharpos(l:lnum, l:column) " set cursor position
  endif
endfunction
