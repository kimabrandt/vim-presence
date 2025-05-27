# vim-presence - Stay focused on the tasks at hand

## Introduction

The vim-presence plugin helps you stay focused when switching between files and
projects.

It works by adding upper case file-marks (global marks) to a
[session-file](https://vimhelp.org/starting.txt.html#session-file) whenever the
[vim-obsession](https://github.com/tpope/vim-obsession#obsessionvim) plugin
saves a session. The marks are then restored, when a session-file is loaded.

Only the global marks listed in the [presence_marks](#gpresence_marks) variable
are managed by this plugin. This gives you some flexibility in how to use it and
integrate it into your workflow.

You can load session files as usual using the `-S` parameter when starting Vim,
or with the `:source` command, after Vim has already started. Alternatively,
with Neovim, you can use the included [Sessions picker](#for-neovim), which
first unloads all buffers before loading the session - useful when switching
between contexts.

There's also a [Marks picker](#for-neovim) that lists your global marks in the
order defined by the [presence_marks](#gpresence_marks) variable.

This README.md is a shortened version of the
[doc/presence.txt](https://github.com/kimabrandt/vim-presence/blob/main/doc/presence.txt)
help file:

```vim
:h presence.txt
```

## Installation

The [vim-presence](https://github.com/kimabrandt/vim-presence) plugin requires
the [vim-obsession](https://github.com/tpope/vim-obsession#obsessionvim) plugin,
so you need to install both.

### Using vim-pathogen ([tpope/vim-pathogen](https://github.com/tpope/vim-pathogen))

Clone both repositories into your ~/.vim/bundle directory:

```sh
cd ~/.vim/bundle
git clone https://github.com/tpope/vim-obsession.git
git clone https://github.com/kimabrandt/vim-presence.git
```

### Using Vundle.vim ([VundleVim/Vundle.vim](https://github.com/VundleVim/Vundle.vim))

Add these Plugin-lines to your init.vim:

```vim
call vundle#begin()
Plugin 'tpope/vim-obsession'
Plugin 'kimabrandt/vim-presence'
call vundle#end()
```

### Using vim-plug ([junegunn/vim-plug](https://github.com/junegunn/vim-plug))

Add these Plug-lines to your init.vim:

```vim
call plug#begin()
Plug 'tpope/vim-obsession'
Plug 'kimabrandt/vim-presence'
call plug#end()
```

### Using lazy.nvim ([folke/lazy.nvim](https://github.com/folke/lazy.nvim))

Add this plugin spec to your init.lua:

```lua
require("lazy").setup({
    spec = {
        "tpope/vim-obsession",
        "kimabrandt/vim-presence"
    }
})
```

## Quickstart

### For Vim

Add this to your init.vim:

```vim
call plug#begin()
Plug 'tpope/vim-obsession'
Plug 'kimabrandt/vim-presence'
call plug#end()

let g:presence_marks = "JKLHGFDSA" " home row keys (qwerty-layout)
nnoremap mm :call presence#add_global_mark_and_shift_backward()<cr>
nnoremap me :call presence#add_global_mark_to_the_end_and_replace_last()<cr>
nnoremap md :call presence#delete_global_mark_and_shift_forward()<cr>
nnoremap <leader><esc> :call presence#delete_buffers_without_global_marks() \| call presence#remove_gaps_in_marks_list()<cr>
```

### For Neovim

Add this to your init.lua:

```lua
require("lazy").setup({
    spec = {
        {
            "kimabrandt/vim-presence",
            dependencies = {
                "tpope/vim-obsession",
                "nvim-telescope/telescope.nvim",
            },
            config = function()
                vim.g.presence_marks = "JKLHGFDSA" -- home row keys (qwerty-layout)
                vim.g.presence_clear = 1 -- clear the presence_marks

                vim.keymap.set("n", "mm", function() -- assign the current text-position to the highest priority mark
                    vim.cmd("call presence#add_global_mark_and_shift_backward()")
                end)

                vim.keymap.set("n", "me", function() -- assign the current text-position to the lowest priority mark
                    vim.cmd("call presence#add_global_mark_to_the_end_and_replace_last()")
                end)

                vim.keymap.set("n", "md", function() -- remove the highest priority mark
                    vim.cmd("call presence#delete_global_mark_and_shift_forward()")
                end)

                vim.keymap.set("n", "<leader><esc>", function() -- clean up buffers and reorder marks-list
                    vim.cmd([[
                        call presence#delete_buffers_without_global_marks()
                        call presence#remove_gaps_in_marks_list()
                    ]])
                end)

                require("telescope").load_extension("presence")

                vim.keymap.set("n", "<A-s>", function() -- show the session files (with Telescope)
                    require("telescope").extensions["presence"].sessions({
                        sessions_dir = "~/.vim/session"
                    })
                end)

                vim.keymap.set("n", "<A-m>", function() -- show the list of global marks (with Telescope)
                    require("telescope").extensions["presence"].marks()
                end)

            end,
        },
    },
})
```

## Configuration

### g:presence_marks

This global variable controls which global marks are tracked and saved in a
session-file, and restored when loading the session-file.

```vim
let g:presence_marks = "JKLHGFDSA" " home row keys (qwerty-layout)
```

By default, all marks (from A to Z) are taken into account. If you set
[presence_marks](#gpresence_marks), only the specified marks will be handled -
any others will be ignored.

You can also temporarily override this list using the marks option when
launching the [Marks picker](#for-neovim). See the
[doc/presence.txt](https://github.com/kimabrandt/vim-presence/blob/main/doc/presence.txt)
for more info.

### g:presence_clear

This global variable tells the plugin to either clear the
[presence_marks](#gpresence_marks) list before restoring a session or leave it
be. The default is, to clear the marks list.

```vim
let g:presence_clear = 0 " don't clear the presence_marks
let g:presence_clear = 1 " clear the presence_marks
```

## Usage

### Start a new session

In Vim, start tracking your current session:

```vim
:Obsession ~/.vim/session/project-xyz.vim
```

This will automatically track files, marks, and more, saving them to the
session file.

### Load a session from the terminal

Source a session-file from the command line:
```sh
vim -S ~/.vim/session/project-xyz.vim
```
This will open files from the session-file and restore the saved marks.

### Load a session from inside Vim

Alternatively, source a session-file from inside Vim:
```vim
:source ~/.vim/session/project-xyz.vim
```
This works the same as using the `-S` parameter - files and marks will be
restored.

### Load a session with Telescope

You can also use the Telescope extension, provided by vim-presence for easy
session picking:

```lua
require("lazy").setup({
    spec = {
        {
            "kimabrandt/vim-presence",
            dependencies = {
                "tpope/vim-obsession",
                "nvim-telescope/telescope.nvim",
            },
            config = function()
                require("telescope").load_extension("presence")
            end,
        },
    },
})
```

Open the Sessions picker with a keymap:

```lua
vim.keymap.set("n", "<A-s>", function()
    require("telescope").extensions["presence"].sessions()
end)
```

Alternatively, with the command:

```vim
:Telescope presence sessions
```

### Jump to a global mark

With Vim:

```vim
nnoremap <A-j> `J
nnoremap <A-k> `K
nnoremap <A-l> `L
" and so on...
```

With Neovim:

```lua
vim.keymap.set("n", "<A-j>", "`J")
vim.keymap.set("n", "<A-k>", "`K")
vim.keymap.set("n", "<A-l>", "`L")
-- and so on...
```

Hold `<Alt>` and effortlessly navigate to important locations in your project by
pressing the respective letter.

### Jump to a global mark with Telescope

You can also jump to a mark using the provided Telescope extension. Load the
extension as before and open the Marks picker with a keymap:

```lua
vim.keymap.set("n", "<A-m>", function()
    require("telescope").extensions["presence"].marks()
end)
```

# Functions

Functions, supported by this plugin, are described in the
[doc/presence.txt](https://github.com/kimabrandt/vim-presence/blob/main/doc/presence.txt)
help file.

```vim
:h presence-functions
```

# License

MIT License. See LICENSE file for details.
