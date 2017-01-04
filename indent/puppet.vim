" Vim indent file
" Language: Puppet
" Maintainer:   Todd Zullinger <tmz@pobox.com>
" Last Change:  2009 Aug 19
" vim: set sw=4 sts=4:

if exists("b:did_indent")
    finish
endif
let b:did_indent = 1

setlocal autoindent smartindent
setlocal indentexpr=GetPuppetIndent()
setlocal indentkeys+=0],0),0&,0\|,0(,{,0\,

if exists("*GetPuppetIndent")
    finish
endif

function! s:OpenBraceLineAndCol(lnum)
    let save_cursor = getcurpos()
    call cursor(a:lnum, 1)
    let result = searchpairpos('{\|\[\|(', '', '}\|\]\|)', 'nbW')
    call setpos('.', save_cursor)
    return result
endfunction

function! s:OpenBraceChar(lnum)
    let [rlnum, rcol] = s:OpenBraceLineAndCol(a:lnum)
    if rlnum < 1 || rcol < 1
        return ""
    endif
    let rline = getline(rlnum)
    return strcharpart(rline, rcol - 1, 1)
endfunction

function! s:OpenBraceLine(lnum)
    let [rlnum, rcol] = s:OpenBraceLineAndCol(a:lnum)
    return rlnum
endfunction

function! s:OpenBraceCol(lnum)
    let [rlnum, rcol] = s:OpenBraceLineAndCol(a:lnum)
    return rcol - 1
endfunction

function! s:OpenBraceColOrIndentOfOpenBraceLine(lnum)
    let [rlnum, rcol] = s:OpenBraceLineAndCol(a:lnum)
    if rlnum == 0
        return 0
    endif
    let rline = getline(rlnum)
    if rline =~ '^\s*} else {$'
        return indent(rlnum)
    endif
    if rline =~ ': {'
        return indent(rlnum)
    endif
    if rline =~ '| {$' && strcharpart(rline, rcol - 1, 1) == '{'
      " start of body passed to higher order function
      " look for function name line and base indent on that
      let save_cursor = getcurpos()
      call cursor(rlnum, rcol - 3)
      let [slambdaline, slambacol] = searchpos(') |', 'bW')
      let [openparline, openparcol] = searchpairpos('(', '', ')', 'nbW')
      call setpos('.', save_cursor)
      return indent(openparline)
    endif
    if rline =~ ') {$' && strcharpart(rline, rcol - 1, 1) == '{'
      " end of parameter list or if/unless condition or case, look for start of
      " parenthesis to base indent on that
      let save_cursor = getcurpos()
      call cursor(rlnum, rcol - 3)
      let [rlnum2, rcol2] = searchpairpos('(', '', ')', 'nbW')
      call setpos('.', save_cursor)
      return indent(rlnum2)
    endif
    if rline =~ '^\s*case \$[a-z0-9:_]*\s*{'
      return indent(rlnum)
    endif
    if rline =~ '^\s*[a-z0-9:_]\+ {' && strcharpart(rline, rcol - 1, 1) == '{'
      return indent(rlnum)
    endif
    if rline =~ '^\s*\(function\|class\|define\) [a-z:_]*($' && strcharpart(rline, rcol - 1, 1) == '('
      return indent(rlnum)
    endif
    return rcol - 1
endfunction

function! s:PrevNonBlankNonComment(lnum)
    let res = prevnonblank(a:lnum - 1)
    while getline(res) =~ '^\s*#'
        let res = prevnonblank(res - 1)
    endwhile
    return res
endfunction

function! GetPuppetIndent()
    let pnum = s:PrevNonBlankNonComment(v:lnum)
    if pnum == 0
       return 0
    endif

    let ppnum = s:PrevNonBlankNonComment(pnum)
    if ppnum != 0
      let ppline = getline(ppnum)
    endif

    let line = getline(v:lnum)
    let pline = getline(pnum)
    let ind = indent(pnum)

    " Utrecht style leading commas
    if line =~ '^\s*,' && s:OpenBraceChar(v:lnum) != '['
        let ind = indent(s:OpenBraceLine(v:lnum)) + &sw
    endif

    if pline =~ '^\s*case \$[a-z0-9:_]*\s*{'
        return indent(pnum)
    endif

    " Lines after lines with unclosed square brackets or curly braces
    " should align to the open brace
    if pline =~ '\[[^\]]*$' || pline =~ '{[^}]*$'
        let ind = s:OpenBraceColOrIndentOfOpenBraceLine(v:lnum)
    endif

    " multi-line condition
    if line =~ '^\s*\(&\||\)'
        let ind = s:OpenBraceCol(v:lnum) + 1
    endif

    " body of else
    if pline =~ '^\s*} else {$'
        let ind = indent(pnum) + &sw
    endif

    " opening { of if or case body
    if pline =~ ') {$'
        if pline =~ '^\s*) {$'
          " multi-line condition if
          let ind = indent(s:OpenBraceLine(v:lnum))
        else
          if pline =~ '^\s*if\>'
            " single-line condition if
            let ind = indent(s:OpenBraceLine(v:lnum)) + &sw
          elseif pline =~ '^\s*case\>'
            let ind = indent(s:OpenBraceLine(v:lnum))
          endif
        endif
    endif

    " opening of higher order function lambda body
    if pline =~ '| {'
        let ind = s:OpenBraceColOrIndentOfOpenBraceLine(v:lnum) + &sw
    endif

    " opening of resource body
    if pline =~ ':$'
        let ind = indent(s:OpenBraceLine(v:lnum)) + &sw + 2
    elseif pline =~ ';$' && pline !~ '[^:]\+:.*[=+]>.*'
        let ind = indent(pnum) - &sw
    endif

    " Match } }, }; ] ]: ], ];
    if line =~ '^\s*\(}\(,\|;\)\?$\|]:\|],\|}]\|];\?$\)'
        let ind = s:OpenBraceColOrIndentOfOpenBraceLine(v:lnum)
    endif

    if line =~ '^\s*) {$'
        if getline(s:OpenBraceLine(v:lnum)) =~ '^\s*\(function\|class\|define\)'
          " closing of parameter list of function, class of defined type
          let ind = s:OpenBraceColOrIndentOfOpenBraceLine(v:lnum) + &sw
        else
          " closing of multi-line if or unless condition
          let ind = s:OpenBraceCol(v:lnum)
        endif
    endif

    " opening of a case body (the per case one, not the main one)
    if pline =~ ': {$'
        if line =~ '^\s*}'
          " empty case body with immediate closing curly brace
          let ind = indent(pnum)
        else
          let ind = indent(pnum) + &sw
        endif
    endif

    " opening of a class, defined type or function
    if pline =~ '^\s*\(function\|class\|define\) [a-z_:]*($'
        let ind = indent(pnum) + &sw + 2
    endif

    " Don't actually shift over for } else {
    if line =~ '^\s*}\s*els\(e\|if\).*{\s*$'
        let ind -= &sw
    endif

    " Don't indent resources that are one after another with a ->(ordering arrow)
    " file {'somefile':
    "    ...
    " } ->
    "
    " package { 'mycoolpackage':
    "    ...
    " }
    if line =~ '->$'
        let ind -= &sw
    endif


    return ind
endfunction
