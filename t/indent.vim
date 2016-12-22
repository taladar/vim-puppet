set encoding=utf-8
scriptencoding utf-8
set nocompatible
set tabstop=2
set shiftwidth=2
set expandtab
set softtabstop=2
set autoindent
set backspace=indent,eol,start
set formatoptions-=t
set textwidth=0 wrapmargin=0

filetype plugin indent on
syntax on

if has('vim_starting')
  set runtimepath+=/home/taladar/.vim/bundle/vim-puppet
  " set runtimepath+=/home/taladar/.vim/bundle/vim-closer
endif

describe 'indentation on new line'

  before
    new
    set filetype=puppet
    " let b:closer = 1
    " let b:closer_flags = '([{'
    " call closer#enable()
  end

  after
    close!
  end

  it 'starts on column 1 on first line'
    Expect line('.') == 1
    Expect col('.') == 1
  end

  it 'moves to line 2, column 1 on return on line 1 column 1'
    Expect line('.') == 1
    Expect col('.') == 1
    execute "normal i\<CR>"
    Expect GetPuppetIndent() == 0
    Expect line('.') == 2
    Expect col('.') == 1
  end

  it 'indents by 4 spaces on return after a resource start'
    Expect line('.') == 1
    Expect col('.') == 1
    execute "normal ifoo { 'bar':\<CR> "
    Expect GetPuppetIndent() == 4
    Expect getline(1) == "foo { 'bar':"
    Expect getline(2) == '     '
    Expect line('.') == 2
    Expect col('.') == 5
  end

  it 'indents by 4 spaces on o on resource start line'
    Expect line('.') == 1
    Expect col('.') == 1
    execute "normal ifoo { 'bar':\<ESC>o "
    Expect GetPuppetIndent() == 4
    Expect getline(1) == "foo { 'bar':"
    Expect getline(2) == '     '
    Expect line('.') == 2
    Expect col('.') == 5
  end

  it 'indents comma by 2 spaces on return after initial parameter of resource'
    Expect line('.') == 1
    Expect col('.') == 1
    execute "normal ifoo { 'bar':\<CR>hello => world\<CR>, baz"
    Expect GetPuppetIndent() == 2
    Expect getline(1) == "foo { 'bar':"
    Expect getline(3) == '  , baz'
    Expect line('.') == 3
    Expect col('.') == 7
  end

  it 'unindents the closing curly brace in a parameter-less resource'
    Expect line('.') == 1
    Expect col('.') == 1
    execute "normal ifoo { 'bar':\<CR>}"
    Expect GetPuppetIndent() == 0
    Expect getline(1) == "foo { 'bar':"
    Expect getline(2) == '}'
    Expect line('.') == 2
    Expect col('.') == 1
  end

  it 'unindents the closing curly brace in a single parameter resource'
    Expect line('.') == 1
    Expect col('.') == 1
    execute "normal ifoo { 'bar':\<CR>hello => world\<CR>}"
    Expect GetPuppetIndent() == 0
    Expect getline(1) == "foo { 'bar':"
    Expect getline(3) == '}'
    Expect line('.') == 3
    Expect col('.') == 1
  end

  it 'unindents the closing curly brace in a two parameter resource'
    Expect line('.') == 1
    Expect col('.') == 1
    execute "normal ifoo { 'bar':\<CR>hello => world\<CR>, foo => bar\<CR>}"
    Expect GetPuppetIndent() == 0
    Expect getline(1) == "foo { 'bar':"
    Expect getline(4) == '}'
    Expect line('.') == 4
    Expect col('.') == 1
  end

  it 'indents a comma after opening resource title array to open square bracket column'
    Expect line('.') == 1
    Expect col('.') == 1
    execute "normal ifoo { [ 'bar'\<CR>,"
    Expect GetPuppetIndent() == 6
    Expect getline(1) == "foo { [ 'bar'"
    Expect getline(2) == '      ,'
    Expect line('.') == 2
    Expect col('.') == 7
  end

  it 'indents a comma later in resource title array to previous line comma'
    Expect line('.') == 1
    Expect col('.') == 1
    execute "normal ifoo { [ 'bar'\<CR>, 'baz'\<CR>,"
    Expect GetPuppetIndent() == 6
    Expect getline(1) == "foo { [ 'bar'"
    Expect getline(2) == "      , 'baz'"
    Expect getline(3) == '      ,'
    Expect line('.') == 3
    Expect col('.') == 7
  end

  it 'indents a closing square bracket after opening resource title array to open square bracket column'
    Expect line('.') == 1
    Expect col('.') == 1
    execute "normal ifoo { [ 'bar'\<CR>]"
    Expect GetPuppetIndent() == 6
    Expect getline(1) == "foo { [ 'bar'"
    Expect getline(2) == '      ]'
    Expect line('.') == 2
    Expect col('.') == 7
  end

  it 'indents a closing square bracket later in resource title array to open square bracket column'
    Expect line('.') == 1
    Expect col('.') == 1
    execute "normal ifoo { [ 'bar'\<CR>, 'baz'\<CR>]"
    Expect GetPuppetIndent() == 6
    Expect getline(1) == "foo { [ 'bar'"
    Expect getline(3) == '      ]'
    Expect line('.') == 3
    Expect col('.') == 7
  end
end
