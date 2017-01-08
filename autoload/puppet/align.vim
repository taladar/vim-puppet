function! puppet#align#IndentLevel(lnum)
    return indent(a:lnum) / &shiftwidth
endfunction

" for use in formatexpr
function! puppet#align#Format()
    let startline = v:lnum
    let linecount = v:count
    let lastline = startline + linecount - 1
    let linesafter = line('$') - lastline
    let range = printf('%d,%d', startline, lastline)
    " add a single space after leading comma without one
    execute range . ':s/^\(\s*\),\(\S\)/\1, \2/e'
    " condense multiple spaces after leading comma into one
    execute range . ':s/^\(\s*\),\(\s\+\)\(\S\)/\1, \3/e'
    " remove space between if and (
    execute range . ':s/^\(\s*\)if\s*(/\1if(/e'
    " join { after if line to end of if line
    execute range . ':s/^\(\s*\)if(\(.*\))\_\s*{$/\1if(\2) {/e'
    let lastline = line('$') - linesafter
    let range = printf('%d,%d', startline, lastline)
    " join { after class line to end of class line
    execute range . ':s/^\(\s*\)class\s*\(\S*\)\_\s*{$/\1class \2 {/e'
    let lastline = line('$') - linesafter
    let range = printf('%d,%d', startline, lastline)
    " exactly one space between ) and {
    execute range . ':s/)\s*{/) {/e'
    " remove trailing whitespace
    execute range . ':s/\s*$//e'
    " resources with newline after {
    execute range . ':s/^\(\s*[a-z0-9_:]*[a-z0-9_]\) {\_\s*/\1 { /e'
    " array concatenations with + at the end of the line, move + to start of
    " line
    execute range . ':s/\s*+\n\( *\)/\1+ /e'
    " TODO: add empty line between resources,...
    " TODO: break long single line hash or array into array with one element
    "       per line

    call cursor(startline, 1)
    execute 'normal! ' . printf('%d', linecount) . 'V='

    call cursor(startline, 1)

    let arrowpos = searchpos('=>', 'W', startline + linecount)
    while arrowpos[0] > 0 || arrowpos[1] > 0
      call cursor(arrowpos[0], arrowpos[1])
      call puppet#align#AlignArrows()

      search('[{}]', 'W')
      let arrowpos = searchpos('=>', 'W', startline + linecount)
    endwhile

    call cursor(startline, 1)
    execute 'normal! ' . printf('%d', linecount) . 'V='
endfunction

" finds all the arrows for alignment, i.e. those within the same {} block
" and without those inside nested hashes
" treats EOF as } for this purpose
" returns a list of [line, column] lists
function! puppet#align#FindArrows()
    let save_cursor = getcurpos()
    let result = []

    let [slnum, scol] = searchpairpos('{', ';$', '}', 'nbW')
    let [elnum, ecol] = searchpairpos('{', ';$', '}', 'nW')
    call cursor(slnum, scol)
    let prevarrowlnum = - 1
    let [arrowlnum, arrowcol] = searchpos('=>', 'W')
    while  arrowlnum >= 1 && arrowcol >= 1 && ((elnum <= 0 || arrowlnum < elnum) || (elnum <= 0 || ecol <= 0 || (arrowlnum == elnum && arrowcol < ecol)))
      let [arrowopencurlylnum, arrowopencurlycol] = searchpairpos('{', ';$', '}', 'nbW')
      if arrowopencurlylnum != slnum || arrowopencurlycol != scol
        " we are in a nested hash
        let prevarrowlnum = arrowlnum
        let [arrowlnum, arrowcol] = searchpos('=>', 'W')
        continue
      endif

      if prevarrowlnum > 0 && prevarrowlnum == arrowlnum
        " we are on the second or later arrow in this hash on this line
        let prevarrowlnum = arrowlnum
        let [arrowlnum, arrowcol] = searchpos('=>', 'W')
        continue
      endif

      call add(result, [arrowlnum, arrowcol])
      let prevarrowlnum = arrowlnum
      let [arrowlnum, arrowcol] = searchpos('=>', 'W')
    endwhile

    call setpos('.', save_cursor)
    return result
endfunction

function! puppet#align#FindArrowsWithLineCounts()
    let [elnum, ecol] = searchpairpos('{', ';$', '}', 'nW')
    if elnum == 0 && ecol == 0
        let [elbuf, elnum, ecol, eloff] = getpos('$')
    endif

    let arrows = puppet#align#FindArrows()

    let arrowswithlinecounts = []
    for [arrowlnum, arrowcol] in arrows
        let added = 0
        for [nextarrowlnum, nextarrowcol] in arrows[1:-1]
            if nextarrowlnum < arrowlnum  || (nextarrowlnum == arrowlnum && nextarrowcol <= arrowcol)
                continue
            endif
            let added = added + 1
            call add(arrowswithlinecounts, [arrowlnum, arrowcol, (nextarrowlnum - arrowlnum)])
            break
        endfor
        if added == 0
            call add(arrowswithlinecounts, [arrowlnum, arrowcol, elnum - arrowlnum])
        endif
    endfor

    return arrowswithlinecounts
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
    let save_cursor  = getcurpos()

    let [slnum, scol] = searchpairpos('\({\|(\)', ';$', '\(}\|)\)', 'nbW')
    if slnum == 0 && scol == 0
        return
    endif

    let arrowswithlinecounts = puppet#align#FindArrowsWithLineCounts()
    let aligncol = puppet#align#FindAlignColumn()

    for [arrowlnum, arrowcol,linecount] in arrowswithlinecounts
      call cursor(arrowlnum, arrowcol)
      if arrowcol == aligncol
        continue
      endif
      if arrowcol > aligncol
        execute "normal! " . (arrowcol - aligncol) . "X"
      else
        execute "normal! " . (aligncol - arrowcol) . "i \<ESC>"
      endif
      let c = 1
      while c < linecount
          call cursor(arrowlnum + c, 1)
          if arrowcol > aligncol
            execute "normal! " . (arrowcol - aligncol) . "x"
          else
            execute "normal! " . (aligncol - arrowcol) . "i \<ESC>"
          endif
          let c = c + 1
      endwhile
    endfor

    call setpos('.', save_cursor)
endfunction
