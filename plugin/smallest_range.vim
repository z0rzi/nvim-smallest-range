if exists('g:loaded_smallest_range') | finish | endif " prevent loading file twice

let s:save_cpo = &cpo " save user coptions
set cpo&vim " reset them to defaults

" mapping smallest range to 'o'
" command! FixBraces lua require("smallest_range").smallest_range()
onoremap <silent> o <CMD>lua require("smallest_range").select_smallest_range()<CR>

let &cpo = s:save_cpo " and restore after
unlet s:save_cpo

let g:loaded_smallest_range = 1
