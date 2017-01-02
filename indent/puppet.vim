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
setlocal indentkeys+=0],0),0&,0\|,0(

if exists("*GetPuppetIndent")
    finish
endif

function! s:OpenBraceLine(lnum)
    let save_cursor = getcurpos()
    call cursor(a:lnum, 1)
    let [rlnum, rcol] = searchpairpos('{\|\[\|(', '', '}\|\]\|)', 'nbW')
    call setpos('.', save_cursor)
    return rlnum
endfunction

function! s:OpenBraceCol(lnum)
    let save_cursor = getcurpos()
    call cursor(a:lnum, 1)
    let [rlnum, rcol] = searchpairpos('{\|\[\|(', '', '}\|\]\|)', 'nbW')
    call setpos('.', save_cursor)
    return rcol
endfunction

function! s:OpenBraceColOrIndentOfOpenBraceLine(lnum)
    let save_cursor = getcurpos()
    call cursor(a:lnum, 1)
    let [rlnum, rcol] = searchpairpos('{\|\[\|(', '', '}\|\]\|)', 'nbW')
    call setpos('.', save_cursor)
    if rlnum == 0
        return 0
    endif
    let rline = getline(rlnum)
    if rline =~ '^\s*\([a-z0-9:]\+\|\(if\|unless\|case\)(.*)\) {' && strcharpart(rline, rcol - 1, 1) == '{'
      return indent(rlnum)
    endif
    return rcol - 1
endfunction

function! GetPuppetIndent()
    let pnum = prevnonblank(v:lnum - 1)
    if pnum == 0
       return 0
    endif

    let ppnum = prevnonblank(pnum - 1)
    if ppnum != 0
      let ppline = getline(ppnum)
    endif

    let line = getline(v:lnum)
    let pline = getline(pnum)
    let ind = indent(pnum)

    if pline =~ '^\s*#'
        return indent(s:OpenBraceLine(pnum))
    endif

    " Utrecht style leading commas for resources
    if ppnum != 0 && pline =~ '^    ' && ppline =~ ':$'
        let ind = indent(s:OpenBraceLine(v:lnum)) + &sw
    endif

    " Lines after lines with unclosed square brackets or curly braces
    " should align to the open brace
    if pline =~ '\[[^\]]*$' || pline =~ '{[^}]*$'
        let ind = s:OpenBraceColOrIndentOfOpenBraceLine(v:lnum)
    endif

    " multi-line condition
    if line =~ '^\s*\(&\||\)'
        let ind = s:OpenBraceCol(v:lnum)
    endif

    " opening { of if or case body
    if pline =~ ') {$'
        if pline =~ '^\s*) {$'
          " multi-line condition if
          let ind = indent(s:OpenBraceLine(v:lnum))
        else
          if pline =~ '^\s*if('
            " single-line condition if
            let ind = indent(s:OpenBraceLine(v:lnum)) + &sw
          elseif pline =~ '^\s*case('
            let ind = indent(s:OpenBraceLine(v:lnum))
          endif
        endif
    endif

    " opening of resource body
    if pline =~ ':$'
        let ind = indent(s:OpenBraceLine(v:lnum)) + 2 * &sw
    elseif pline =~ ';$' && pline !~ '[^:]\+:.*[=+]>.*'
        let ind -= &sw
    endif

    " Match } }, }; ] ]: ], ]; )
    if line =~ '^\s*\(}\(,\|;\)\?$\|]:\|],\|}]\|];\?$\|)\)'
        let ind = s:OpenBraceColOrIndentOfOpenBraceLine(v:lnum)
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
