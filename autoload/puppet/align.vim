function! puppet#align#IndentLevel(lnum)
    return indent(a:lnum) / &shiftwidth
endfunction

" for use in formatexpr
function! puppet#align#Format()
    let range = printf('%d,%d', v:lnum, v:lnum + v:count - 1)
    " add a single space after leading comma without one
    execute range . ':s/^\(\s*\),\(\S\)/\1, \2/'
    " condense multiple spaces after leading comma into one
    execute range . ':s/^\(\s*\),\(\s\+\)\(\S\)/\1, \3/'
    " join { after if line to end of if line
    execute range . ':s/^\(\s*\)if(\(.*\))\_\s*{$/\1if(\2) {/'
    " TODO: add empty line between resources,...

    call cursor(v:lnum, 1)

    " this could be done more efficiently, this way we re-align once per arrow
    let arrowpos = searchpos('=>', 'W', v:lnum + v:count)
    while arrowpos[0] != 0 || arrowpos[1] != 0
      call cursor(arrowpos[0], 99999)
      call puppet#align#AlignArrows()

      let arrowpos = searchpos('=>', 'W', v:lnum + v:count)
    endwhile

    call cursor(v:lnum, 1)
    execute 'normal! ' . printf('%d', v:count) . 'V='
endfunction

" finds all the arrows for alignment, i.e. those within the same {} block
" and without those inside nested hashes
" treats EOF as } for this purpose
" returns a list of [line, column] lists
function! puppet#align#FindArrows()
    let save_cursor = getcurpos()
    let result = []

    let [slnum, scol] = searchpairpos('{', '', '}', 'nbW')
    let [elnum, ecol] = searchpairpos('{', '', '}', 'nW')
    call cursor(slnum, scol)
    let [arrowlnum, arrowcol] = searchpos('=>', 'W')
    while  arrowlnum >= 1 && arrowcol >= 1 && ((elnum <= 0 || arrowlnum < elnum) || (elnum <= 0 || ecol <= 0 || (arrowlnum == elnum && arrowcol < ecol)))
      let [arrowopencurlylnum, arrowopencurlycol] = searchpairpos('{', '', '}', 'nbW')
      if arrowopencurlylnum == slnum && arrowopencurlycol == scol
        " we are not in a nested hash
        call add(result, [arrowlnum, arrowcol])
      endif
      let [arrowlnum, arrowcol] = searchpos('=>', 'W')
    endwhile

    call setpos('.', save_cursor)
    return result
endfunction

" Finds the column where the aligned arrows need to start
function! puppet#align#FindAlignColumn()
    let save_cursor = getcurpos()
    let result = -1

    let arrows = puppet#align#FindArrows()

    for [arrowlnum, arrowcol] in arrows
      call cursor(arrowlnum, arrowcol)
      let [keyendlnum, keyendcol] = searchpos('\S', 'nbW')
      let result = max([result, keyendcol + 2])
    endfor

    call setpos('.', save_cursor)
    return result
endfunction

" for this to work the cursor needs to be within the same curly braces or
" parentheses as the arrows to align
function! puppet#align#AlignArrows()
    let [ save_buf, save_lnum, save_col, save_off, save_curs_want ]  = getcurpos()

    let [slnum, scol] = searchpairpos('\({\|(\)', '', '\(}\|)\)', 'nbW')
    if slnum == 0 && scol == 0
        return
    endif

    let arrows = puppet#align#FindArrows()
    let aligncol = puppet#align#FindAlignColumn()

    for [arrowlnum, arrowcol] in arrows
      call cursor(arrowlnum, arrowcol)
      if arrowcol == aligncol
        continue
      endif
      if arrowcol > aligncol
        execute "normal! " . (arrowcol - aligncol) . "X"
      else
        execute "normal! " . (aligncol - arrowcol) . "i \<ESC>"
      endif
    endfor

    call setpos('.', [save_buf, save_lnum, save_col, save_off, save_curs_want])
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
