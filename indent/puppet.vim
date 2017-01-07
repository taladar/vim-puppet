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
setlocal indentkeys+=0],0),0=and,0=or,0(,{,0\,

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

    " TODO: indent of first line after resource title in semicolon limited
    " resources

    if pline =~ '^\s*case \$[a-z0-9:_]*\s*{'
        return indent(pnum)
    endif

    " Utrecht style leading commas
    if line =~ '^\s*,'
        if pline =~ '^\s*,' && s:OpenBraceLine(v:lnum) < pnum
            return indent(pnum)
        elseif pline =~ '^\s*}$' || pline =~ '^\s*\]$'
            " nested hash or array end
            let obl = s:OpenBraceLine(pnum)
            if getline(obl) =~ '^\s*,'
              return indent(obl)
            else
              return indent(obl) - 2
            endif
        elseif getline(s:OpenBraceLine(v:lnum)) =~ ':$'
            return indent(s:OpenBraceLine(v:lnum)) + &sw
        elseif getline(s:OpenBraceLine(v:lnum)) =~ '{ \[' && s:OpenBraceChar(v:lnum) == '{'
            return indent(s:OpenBraceLine(v:lnum)) + &sw
        elseif getline(s:OpenBraceLine(v:lnum)) =~ ') {$'
            return indent(s:OpenBraceLine(v:lnum)) + &sw
        elseif s:OpenBraceChar(v:lnum) == '('
            return indent(s:OpenBraceLine(v:lnum)) + &sw
        else
            return s:OpenBraceCol(v:lnum)
        endif
    endif

    " opening of higher order function lambda body
    if getline(s:OpenBraceLine(v:lnum)) =~ '| {$'
        if line =~ '^\s*}$'
            return indent(s:OpenBraceLine(v:lnum))
        else
            return indent(s:OpenBraceLine(v:lnum)) + &sw
        endif
    endif

    " if, main case, class, defined type or function body
    if getline(s:OpenBraceLine(v:lnum)) =~ ') {$'
        if getline(s:OpenBraceLine(v:lnum)) =~ '^\s*) {$'
            " multi-line condition if or class/defined type/function parameter
            " list
            if line =~ '^\s*}$'
                return indent(s:OpenBraceLine(s:OpenBraceLine(v:lnum)))
            else
                return indent(s:OpenBraceLine(s:OpenBraceLine(v:lnum))) + &sw
            endif
        elseif getline(s:OpenBraceLine(v:lnum)) =~ '^\s*if\>'
            " single-line condition if
            if line =~ '^\s*}$'
                return indent(s:OpenBraceLine(v:lnum))
            else
                return indent(s:OpenBraceLine(v:lnum)) + &sw
            endif
        elseif getline(s:OpenBraceLine(v:lnum)) =~ '^\s*case\>'
            " main case body is not indented
            return indent(s:OpenBraceLine(v:lnum))
        endif
    endif

    " multi-line condition
    if line =~ '^\s*\(and\|or\)\>'
        return s:OpenBraceCol(v:lnum) + 1
    endif

    " body of else
    if pline =~ '^\s*} else {$'
        return indent(pnum) + &sw
    endif

    if line =~ '^\s*) {$'
        if getline(s:OpenBraceLine(v:lnum)) =~ '^\s*\(function\|class\|define\)'
          " closing of parameter list of function, class of defined type
          return indent(s:OpenBraceLine(v:lnum)) + &sw
        else
          " closing of multi-line if or unless condition
          return s:OpenBraceCol(v:lnum)
        endif
    endif

    " case body (the per case one, not the main one)
    if getline(s:OpenBraceLine(v:lnum)) =~ ': {$'
        if line =~ '^\s*}'
          " empty case body with immediate closing curly brace
          return indent(s:OpenBraceLine(v:lnum))
        else
          return indent(s:OpenBraceLine(v:lnum)) + &sw
        endif
    endif

    " opening of a class with parameter list, defined type or function
    if getline(s:OpenBraceLine(v:lnum)) =~ '^\s*\(function\|class\|define\) [a-z_:]*\s*($'
        if line =~ '^\s*)'
          return indent(s:OpenBraceLine(v:lnum)) + &sw
        else
          return indent(s:OpenBraceLine(v:lnum)) + &sw + 2
        endif
    endif

    " opening of a class without parameter list
    if getline(s:OpenBraceLine(v:lnum)) =~ '^\s*class [a-z_:]*\s*{$'
        if line =~ '^\s*}'
          return indent(s:OpenBraceLine(v:lnum))
        else
          return indent(s:OpenBraceLine(v:lnum)) + &sw
        endif
    endif

    " opening of a node
    if getline(s:OpenBraceLine(v:lnum)) =~ '^\s*node.*{$'
        if line =~ '^\s*}'
          return indent(s:OpenBraceLine(v:lnum))
        else
          return indent(s:OpenBraceLine(v:lnum)) + &sw
        endif
    endif

    " opening of resource body
    if pline =~ ':$'
        if line =~ '^\s*}'
            return indent(s:OpenBraceLine(v:lnum))
        else
            return indent(s:OpenBraceLine(v:lnum)) + &sw + 2
        endif
    elseif pline =~ ';$' && pline !~ '[^:]\+:.*[=+]>.*'
        return indent(pnum) - &sw
    endif

    " line after multi-line array or hash value (e.g. in variable assignment)
    " optionally with + $foo after the ]
    if pline =~ '^\s*\(}\|\]\)\([ $+a-z0-9_]\+\)\?$'
        return indent(s:OpenBraceLine(pnum))
    endif

    " closing square bracket of resource title array
    if line =~ '^\s*\]$'
        return s:OpenBraceCol(v:lnum)
    endif

    if line =~ '^\s*}$'
        let obl = s:OpenBraceLine(v:lnum)
        if getline(obl) =~ ':$'
            " resource without multi-line title array
            return indent(obl)
        elseif getline(obl) =~ '^\s*[a-z0-9_:]\+ { \['
            " resource with multi-line title array
            return indent(obl)
        endif
    endif

    return ind
endfunction
