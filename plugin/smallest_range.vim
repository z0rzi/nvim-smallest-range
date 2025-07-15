if exists('g:loaded_smallest_range') | finish | endif " prevent loading file twice

let s:save_cpo = &cpo " save user coptions
set cpo&vim " reset them to defaults

" mapping smallest range to 'o'
onoremap io <CMD>lua require("smallest_range").select_smallest_range(false, 0)<CR>
onoremap ao <CMD>lua require("smallest_range").select_smallest_range(true, 0)<CR>
nnoremap vio <CMD>lua require("smallest_range").select_smallest_range(false, 0)<CR>
nnoremap vao <CMD>lua require("smallest_range").select_smallest_range(true, 0)<CR>

onoremap zl <CMD>lua require("smallest_range").select_smallest_range(false, 1)<CR>
onoremap zL <CMD>lua require("smallest_range").select_smallest_range(true, 1)<CR>

onoremap zh <CMD>lua require("smallest_range").select_smallest_range(false, -1)<CR>
onoremap zH <CMD>lua require("smallest_range").select_smallest_range(true, -1)<CR>

let &cpo = s:save_cpo " and restore after
unlet s:save_cpo

let g:loaded_smallest_range = 1
