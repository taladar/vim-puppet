if !exists('g:puppet_align_hashes')
    let g:puppet_align_hashes = 1
endif

if g:puppet_align_hashes
    inoremap <buffer> <silent> > ><Esc>:call puppet#align#AlignArrows()<CR>$a
endif
