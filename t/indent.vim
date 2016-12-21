"silent filetype plugin on
"silent filetype indent on
"syntax enable
"set autoindent

"let &runtimepath.=','.escape(expand('<sfile>:p:h'), '\,')
"let &runtimepath.=','.escape(expand('<sfile>:p:h'), '\,').'/after'

describe 'indentation on new line'

  before
    new
    "setlocal filetype=puppet
    "source autoload/puppet/align.vim
    "source indent/puppet.vim
    "source syntax/puppet.vim
    "source ftplugin/puppet.vim
    "Expect &filetype == "puppet"
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
    Expect line('.') == 2
    Expect col('.') == 1
  end

  it 'indents by 4 spaces on return after a resource start'
    Expect line('.') == 1
    Expect col('.') == 1
    execute "normal ifoo { 'bar':\<CR>"
    Expect getline(1) == "foo { 'bar':"
    Expect getline(2) == '    '
    Expect line('.') == 2
    Expect col('.') == 5
  end

  it 'adds an unindented closing brace to line 3 on return after a resource start on line 1'
    Expect line('.') == 1
    Expect col('.') == 1
    execute "normal ifoo { 'bar':\<CR>"
    Expect getline(1) == "foo { 'bar':"
    Expect getline(3) == '}'
    Expect line('.') == 2
    Expect col('.') == 5
  end

  it 'indents comma by 2 spaces on return after initial parameter of resource'
    Expect line('.') == 1
    Expect col('.') == 1
    execute "normal ifoo { 'bar':\<CR>hello => world\<CR>, baz"
    Expect getline(1) == "foo { 'bar':"
    Expect getline(2) == '    hello => world'
    Expect getline(3) == '  , baz'
    Expect getline(4) == '}'
    Expect line('.') == 3
    Expect col('.') == 7
  end
end
