if exists('g:loaded_smallest_range') | finish | endif " prevent loading file twice

let s:save_cpo = &cpo " save user coptions
set cpo&vim " reset them to defaults

" mapping smallest range to 'o'
onoremap io <CMD>lua require("smallest_range").select_smallest_range(false)<CR>
onoremap ao <CMD>lua require("smallest_range").select_smallest_range(true)<CR>
nnoremap vio <CMD>lua require("smallest_range").select_smallest_range(false)<CR>
nnoremap vao <CMD>lua require("smallest_range").select_smallest_range(true)<CR>

let &cpo = s:save_cpo " and restore after
unlet s:save_cpo

let g:loaded_smallest_range = 1
