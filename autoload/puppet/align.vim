function! puppet#align#IndentLevel(lnum)
    return indent(a:lnum) / &shiftwidth
endfunction

" for this to work the cursor needs to be within the same curly braces or
" parentheses as the arrows to align
function! puppet#align#AlignArrows()
    let save_cursor = getcurpos()

    let [slnum, scol] = searchpairpos('\({\|(\)', '', '\(}\|)\)', 'nbW')
    if slnum == 0 && scol == 0
        return
    endif

    let align_col = 0
    let [alnum, acol] = searchpos('=>', 'bW', slnum)
    while (alnum != 0 && acol != 0) && ( alnum > slnum || acol > scol )
      let [aslnum, ascol] = searchpairpos('\({\|(\)', '', '\(}\|)\)', 'nbW')
      if slnum == aslnum && scol == ascol
          " if this is not the case we are inside some sort of nested hash,
          " ignore these for alignment

          let align_col = max([align_col, col('.')])
      endif
      let [alnum, acol] = searchpos('=>', 'bW', slnum)
    endwhile

    call setpos('.', save_cursor)

    let [alnum, acol] = searchpos('=>', 'bW', slnum)
    while (alnum != 0 && acol != 0) && ( alnum > slnum || acol > scol )
      let [aslnum, ascol] = searchpairpos('\({\|(\)', '', '\(}\|)\)', 'nbW')
      if slnum == aslnum && scol == ascol
          " if this is not the case we are inside some sort of nested hash,
          " ignore these for alignment

          let insert_spaces = align_col - col('.')
          let is = printf('%-' . insert_spaces . 's', '')
          execute "normal! i" . is
      endif
      let [alnum, acol] = searchpos('=>', 'bW', slnum)
    endwhile

    call setpos('.', save_cursor)
endfunction

function! puppet#align#LinesInBlock(lnum)
    let lines = []
    let indent_level = puppet#align#IndentLevel(a:lnum)

    let marker = a:lnum - 1
    while marker >= 1
        let line_text = getline(marker)
        let line_indent = puppet#align#IndentLevel(marker)

        if line_text =~? '\v\S'
            if line_indent < indent_level
                break
            elseif line_indent == indent_level
                call add(lines, marker)
            endif
        endif

        let marker -= 1
    endwhile

    let marker = a:lnum
    while marker <= line('$')
        let line_text = getline(marker)
        let line_indent = puppet#align#IndentLevel(marker)

        if line_text =~? '\v\S'
            if line_indent < indent_level
                break
            elseif line_indent == indent_level
                call add(lines, marker)
            endif
        endif

        let marker += 1
    endwhile

    return lines
endfunction

function! puppet#align#AlignHashrockets()
    let lines_in_block = puppet#align#LinesInBlock(line('.'))
    let max_left_len = 0
    let indent_str = printf('%' . indent(line('.')) . 's', '')

    for line_num in lines_in_block
        let data = matchlist(getline(line_num), '^\s*\(.*\S\)\s*=>\s*\(\S.*\|\)$')
        if !empty(data)
            let max_left_len = max([max_left_len, strlen(data[1])])
        endif
    endfor

    for line_num in lines_in_block
        let data = matchlist(getline(line_num), '^\s*\(.*\S\)\s*=>\s*\(\S.*\|\)$')
        if !empty(data)
            if data[2] == ''
              let new_line = printf('%s%-' . max_left_len . 's =>', indent_str, data[1])
              call setline(line_num, new_line)
            else
              let new_line = printf('%s%-' . max_left_len . 's => %s', indent_str, data[1], data[2])
              call setline(line_num, new_line)
            endif
        endif
    endfor
endfunction
