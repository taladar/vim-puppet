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
setlocal indentkeys+=0],0)

if exists("*GetPuppetIndent")
    finish
endif

function! s:OpenBrace(lnum)
    call cursor(a:lnum, 1)
    return searchpair('{\|\[\|(', '', '}\|\]\|)', 'nbW')
endfunction

function! s:OpenBraceLine()
    let [rlnum, rcol] = searchpairpos('{\|\[\|(', '', '}\|\]\|)', 'nbW')
    return rlnum
endfunction

function! s:OpenBraceColOrIndentOfOpenBraceLine()
    let [rlnum, rcol] = searchpairpos('{\|\[\|(', '', '}\|\]\|)', 'nbW')
    if rlnum == 0
        return 0
    endif
    let rline = getline(rlnum)
    if rline =~ '\({\|\[\|(\|:\)$'
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
        return indent(s:OpenBrace(pnum))
    endif

    " Utrecht style leading commas for resources
    if ppnum != 0 && pline =~ '^    ' && ppline =~ ':$'
        let ind = indent(s:OpenBraceLine()) + &sw
    endif

    " Lines after lines with unclosed square brackets or curly braces
    " should align to the open brace
    if pline =~ '\[[^\]]*$' || pline =~ '{[^}]*$'
        let ind = s:OpenBraceColOrIndentOfOpenBraceLine()
    endif

    if pline =~ '\({\|\[\|(\|:\)$'
        let ind += 2 * &sw
    elseif pline =~ ';$' && pline !~ '[^:]\+:.*[=+]>.*'
        let ind -= &sw
    endif

    " Match } }, }; ] ]: ], ]; )
    if line =~ '^\s*\(}\(,\|;\)\?$\|]:\|],\|}]\|];\?$\|)\)'
        let ind = s:OpenBraceColOrIndentOfOpenBraceLine()
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
