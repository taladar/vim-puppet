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

    let oblnum = s:OpenBraceLine(v:lnum)
    let obline = getline(oblnum)
    let obcol = s:OpenBraceCol(v:lnum)
    let obind = indent(oblnum)

    " TODO: indent of first line after resource title in semicolon limited
    " resources
    " TODO: indent of closing } with resource relationship after it
    " TODO: indent of array concatenated to variable in variable assignment
    " TODO: exclude quoted and commented parentheses,... from consideration

    if pline =~ '^\s*case \$[a-z0-9:_]*\s*{'
        return ind
    endif

    " Utrecht style leading commas
    if line =~ '^\s*,'
        if pline =~ '^\s*,' && oblnum < pnum
            return ind
        elseif pline =~ '^\s*}$' || pline =~ '^\s*\]$'
            " nested hash or array end
            let obl = s:OpenBraceLine(pnum)
            if getline(obl) =~ '^\s*,'
              return indent(obl)
            else
              return indent(obl) - 2
            endif
        elseif obline =~ ':$'
            return obind + &sw
        elseif obline =~ '{ \[' && s:OpenBraceChar(v:lnum) == '{'
            return obind + &sw
        elseif obline =~ ') {$'
            return obind + &sw
        elseif s:OpenBraceChar(v:lnum) == '('
            if obline =~ '^\s*\(class\|function\|define\)'
                return obind + &sw
            else
                return obcol
            endif
        else
            return obcol
        endif
    endif

    " opening of higher order function lambda body
    if obline =~ '| {$'
        if line =~ '^\s*}$'
            return obind
        else
            return obind + &sw
        endif
    endif

    " if, main case, class, defined type or function body
    if obline =~ ') {$'
        if obline =~ '^\s*) {$'
            " multi-line condition if or class/defined type/function parameter
            " list
            if line =~ '^\s*}$'
                return indent(s:OpenBraceLine(oblnum))
            else
                return indent(s:OpenBraceLine(oblnum)) + &sw
            endif
        elseif obline =~ '^\s*if\>'
            " single-line condition if
            if line =~ '^\s*}$'
                return obind
            elseif line =~ '^\s*} else {$'
                return obind
            else
                return obind + &sw
            endif
        elseif obline =~ '^\s*case\>'
            " main case body is not indented
            return obind
        endif
    endif

    " if without condition
    if obline =~ '^\s*if.*{$'
        if line =~ '^\s*}'
            return obind
        else
            return obind + &sw
        endif
    endif

    " body of else
    if obline =~ '^\s*} else {$'
        if line =~ '^\s*}$'
            return obind
        else
            return obind + &sw
        endif
    endif

    if line =~ '^\s*) {$'
        if obline =~ '^\s*\(function\|class\|define\)'
          " closing of parameter list of function, class of defined type
          return obind + &sw
        else
          " closing of multi-line if or unless condition
          return obcol
        endif
    endif

    " case body (the per case one, not the main one)
    if obline =~ ': {$'
        if line =~ '^\s*}'
          " empty case body with immediate closing curly brace
          return obind
        else
          return obind + &sw
        endif
    endif

    " multi-line condition
    if line =~ '^\s*\(and\|or\)\>'
        return obcol + 1
    endif

    " opening of a class with parameter list, defined type or function
    if obline =~ '^\s*\(function\|class\|define\) [a-z_:]*\s*($'
        if line =~ '^\s*)'
          return obind + &sw
        else
          return obind + &sw + 2
        endif
    endif

    " opening of a class without parameter list
    if obline =~ '^\s*class [a-z_:]*\s*{$'
        if line =~ '^\s*}'
          return obind
        else
          return obind + &sw
        endif
    endif

    " opening of a node
    if obline =~ '^\s*node.*{$'
        if line =~ '^\s*}'
          return obind
        else
          return obind + &sw
        endif
    endif

    " opening of resource body
    if pline =~ ':$'
        if line =~ '^\s*}'
            return obind
        else
            return obind + &sw + 2
        endif
    elseif pline =~ ';$' && pline !~ '[^:]\+:.*[=+]>.*'
        return ind - &sw
    endif

    " line after multi-line array or hash value (e.g. in variable assignment)
    " optionally with + $foo after the ]
    if pline =~ '^\s*\(}\|\]\)\([ $+a-z0-9_]\+\)\?$'
        return indent(s:OpenBraceLine(pnum))
    endif

    " closing square bracket of resource title array
    if line =~ '^\s*\]$'
        return obcol
    endif

    if line =~ '^\s*}$'
        if obline =~ ':$'
            " resource without multi-line title array
            return obind
        elseif obline =~ '^\s*[a-z0-9_:]\+ { \['
            " resource with multi-line title array
            return obind
        endif
    endif

    return ind
endfunction
