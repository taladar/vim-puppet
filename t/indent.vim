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

describe 'indentation on new line =>'

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

  context "basics =>"
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
  end

  context "resources =>"
    context "with title string =>"
      context "first parameter =>"
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

        it 'indents comma in array parameter value on first parameter to open square bracket column'
          Expect line('.') == 1
          Expect col('.') == 1
          execute "normal ifoo { 'bar':\<ESC>ofoo => [ 'hello'\<CR>,"
          Expect getline(1) == "foo { 'bar':"
          Expect getline(2) == "    foo => [ 'hello'"
          Expect GetPuppetIndent() == 11
          Expect getline(3) == '           ,'
          Expect line('.') == 3
          Expect col('.') == 12
        end

        it 'indents closing square bracket in array parameter value on first parameter to open square bracket column'
          Expect line('.') == 1
          Expect col('.') == 1
          execute "normal ifoo { 'bar':\<ESC>ofoo => [ 'hello'\<CR>, 'world'\<CR>]"
          Expect getline(1) == "foo { 'bar':"
          Expect getline(2) == "    foo => [ 'hello'"
          Expect getline(3) == "           , 'world'"
          Expect GetPuppetIndent() == 11
          Expect getline(4) == "           ]"
          Expect line('.') == 4
          Expect col('.') == 12
        end

        it 'indents comma in hash parameter value on first parameter to open curly brace column'
          Expect line('.') == 1
          Expect col('.') == 1
          execute "normal ifoo { 'bar':\<ESC>ofoo => { 'hello' => 'world'\<CR>,"
          Expect getline(1) == "foo { 'bar':"
          Expect getline(2) == "    foo => { 'hello' => 'world'"
          Expect GetPuppetIndent() == 11
          Expect getline(3) == '           ,'
          Expect line('.') == 3
          Expect col('.') == 12
        end

        it 'indents comma in hash parameter value on first parameter to open curly brace column after filling in the value arrow on the line'
          Expect line('.') == 1
          Expect col('.') == 1
          execute "normal ifoo { 'bar':\<ESC>ofoo => { 'hello' => 'world'\<CR>, 'foo' => $bar"
          Expect getline(1) == "foo { 'bar':"
          Expect getline(2) == "    foo => { 'hello' => 'world'"
          Expect GetPuppetIndent() == 11
          Expect getline(3) == "           , 'foo'   => $bar"
          Expect line('.') == 3
          Expect col('.') == 28
        end

        it 'indents closing curly brace in hash parameter value on first parameter to opening curly brace column'
          Expect line('.') == 1
          Expect col('.') == 1
          execute "normal ifoo { 'bar':\<ESC>ofoo => { 'hello' => 'world'\<CR>, 'foo' => $bar\<CR>}"
          Expect getline(1) == "foo { 'bar':"
          Expect getline(2) == "    foo => { 'hello' => 'world'"
          Expect getline(3) == "           , 'foo'   => $bar"
          Expect GetPuppetIndent() == 11
          Expect getline(4) == "           }"
          Expect line('.') == 4
          Expect col('.') == 12
        end

        it 'indents second parameter line after hash parameter value on first parameter to correct column'
          Expect line('.') == 1
          Expect col('.') == 1
          execute "normal ifoo { 'bar':\<ESC>ofoo => { 'hello' => 'world'\<CR>, 'foo' => $bar\<CR>}\<CR>,"
          Expect getline(1) == "foo { 'bar':"
          Expect getline(2) == "    foo => { 'hello' => 'world'"
          Expect getline(3) == "           , 'foo'   => $bar"
          Expect getline(4) == "           }"
          Expect GetPuppetIndent() == 2
          Expect getline(5) == "  ,"
          Expect line('.') == 5
          Expect col('.') == 3
        end
      end

      context "further parameters =>"
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

        it 'indents comma in array parameter value on second parameter to open square bracket column'
          Expect line('.') == 1
          Expect col('.') == 1
          execute "normal ifoo { 'bar':\<ESC>obaz => quux\<CR>, foo => [ 'hello'\<CR>,"
          Expect getline(1) == "foo { 'bar':"
          Expect getline(2) == "    baz => quux"
          Expect getline(3) == "  , foo => [ 'hello'"
          Expect GetPuppetIndent() == 11
          Expect getline(4) == '           ,'
          Expect line('.') == 4
          Expect col('.') == 12
        end

        it 'indents closing square bracket in array parameter value on first parameter to open square bracket column'
          Expect line('.') == 1
          Expect col('.') == 1
          execute "normal ifoo { 'bar':\<ESC>obaz => quux\<CR>, foo => [ 'hello'\<CR>, 'world'\<CR>]"
          Expect getline(1) == "foo { 'bar':"
          Expect getline(2) == "    baz => quux"
          Expect getline(3) == "  , foo => [ 'hello'"
          Expect getline(4) == "           , 'world'"
          Expect GetPuppetIndent() == 11
          Expect getline(5) == "           ]"
          Expect line('.') == 5
          Expect col('.') == 12
        end
      end

      context "closing brace =>"
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

        it 'unindents the closing curly brace in a two parameter resource with type with scope and underscore'
          Expect line('.') == 1
          Expect col('.') == 1
          execute "normal ifoo::bar_baz::baz_quux { 'bar':\<CR>hello => world\<CR>, foo => bar\<CR>}"
          Expect GetPuppetIndent() == 0
          Expect getline(1) == "foo::bar_baz::baz_quux { 'bar':"
          Expect getline(4) == '}'
          Expect line('.') == 4
          Expect col('.') == 1
        end
      end
    end

    context "with title array =>"
      context "title array =>"
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

      context "first parameter =>"
        it 'indents the first line after closing square bracket of resource title array to resource name + 4'
          Expect line('.') == 1
          Expect col('.') == 1
          execute "normal ifoo { [ 'bar'\<CR>, 'baz'\<CR>]:\<CR>foo"
          Expect GetPuppetIndent() == 4
          Expect getline(1) == "foo { [ 'bar'"
          Expect getline(4) == '    foo'
          Expect line('.') == 4
          Expect col('.') == 7
        end

        it 'indents comma in array parameter value on first parameter to open square bracket column'
          Expect line('.') == 1
          Expect col('.') == 1
          execute "normal ifoo { [ 'bar'\<CR>, 'baz'\<CR>]:\<CR>foo => [ 'hello'\<CR>,"
          Expect getline(1) == "foo { [ 'bar'"
          Expect getline(2) == "      , 'baz'"
          Expect getline(3) == "      ]:"
          Expect getline(4) == "    foo => [ 'hello'"
          Expect GetPuppetIndent() == 11
          Expect getline(5) == '           ,'
          Expect line('.') == 5
          Expect col('.') == 12
        end

        it 'indents closing square bracket in array parameter value on first parameter to open square bracket column'
          Expect line('.') == 1
          Expect col('.') == 1
          execute "normal ifoo { [ 'bar'\<CR>, 'baz'\<CR>]:\<CR>foo => [ 'hello'\<CR>, 'world'\<CR>]"
          Expect getline(1) == "foo { [ 'bar'"
          Expect getline(2) == "      , 'baz'"
          Expect getline(3) == "      ]:"
          Expect getline(4) == "    foo => [ 'hello'"
          Expect getline(5) == "           , 'world'"
          Expect GetPuppetIndent() == 11
          Expect getline(6) == '           ]'
          Expect line('.') == 6
          Expect col('.') == 12
        end
      end

      context "further parameters =>"
        it 'indents second line after closing square bracket of resource title array to resource name + 2'
          Expect line('.') == 1
          Expect col('.') == 1
          execute "normal ifoo { [ 'bar'\<CR>, 'baz'\<CR>]:\<CR>foo => bar\<CR>, baz"
          Expect GetPuppetIndent() == 2
          Expect getline(1) == "foo { [ 'bar'"
          Expect getline(5) == '  , baz'
          Expect line('.') == 5
          Expect col('.') == 7
        end

        it 'indents third line after closing square bracket of resource title array to resource name + 2'
          Expect line('.') == 1
          Expect col('.') == 1
          execute "normal ifoo { [ 'bar'\<CR>, 'baz'\<CR>]:\<CR>foo => bar\<CR>, baz => quux\<CR>, hello"
          Expect GetPuppetIndent() == 2
          Expect getline(1) == "foo { [ 'bar'"
          Expect getline(6) == '  , hello'
          Expect line('.') == 6
          Expect col('.') == 9
        end
      end

      context "closing brace =>"
        it 'unindents the closing curly brace in a parameter-less resource with title array'
          Expect line('.') == 1
          Expect col('.') == 1
          execute "normal ifoo { [ 'bar'\<CR>, 'baz'\<CR>]:\<CR>}"
          Expect GetPuppetIndent() == 0
          Expect getline(1) == "foo { [ 'bar'"
          Expect getline(4) == '}'
          Expect line('.') == 4
          Expect col('.') == 1
        end

        it 'unindents the closing curly brace in a single parameter resource with title array'
          Expect line('.') == 1
          Expect col('.') == 1
          execute "normal ifoo { [ 'bar'\<CR>, 'baz'\<CR>]:\<CR>foo => bar\<CR>}"
          Expect GetPuppetIndent() == 0
          Expect getline(1) == "foo { [ 'bar'"
          Expect getline(5) == '}'
          Expect line('.') == 5
          Expect col('.') == 1
        end

        it 'unindents the closing curly brace in a two parameter resource with title array'
          Expect line('.') == 1
          Expect col('.') == 1
          execute "normal ifoo { [ 'bar'\<CR>, 'baz'\<CR>]:\<CR>foo => bar\<CR>, baz => quux\<CR>}"
          Expect GetPuppetIndent() == 0
          Expect getline(1) == "foo { [ 'bar'"
          Expect getline(6) == '}'
          Expect line('.') == 6
          Expect col('.') == 1
        end
      end
    end
  end

  context "if =>"
    context "single line condition =>"
      context "body =>"
        it 'indents body by 2 spaces after hitting return'
          Expect line('.') == 1
          Expect col('.') == 1
          execute "normal iif(foo == bar) {\<CR> "
          Expect GetPuppetIndent() == 2
          Expect getline(1) == "if(foo == bar) {"
          Expect getline(2) == '   '
          Expect line('.') == 2
          Expect col('.') == 3
        end

        it 'indents body by 2 spaces after hitting return after if with and in condition'
          Expect line('.') == 1
          Expect col('.') == 1
          execute "normal iif(foo == bar and baz == quux) {\<CR> "
          Expect GetPuppetIndent() == 2
          Expect getline(1) == "if(foo == bar and baz == quux) {"
          Expect getline(2) == '   '
          Expect line('.') == 2
          Expect col('.') == 3
        end

        it 'indents body by 2 spaces after hitting return when first line of body is empty'
          Expect line('.') == 1
          Expect col('.') == 1
          execute "normal iif(foo == bar) {\<CR>\<CR> "
          Expect GetPuppetIndent() == 2
          Expect getline(1) == "if(foo == bar) {"
          Expect getline(2) == ''
          Expect getline(3) == '   '
          Expect line('.') == 3
          Expect col('.') == 3
        end

        it 'indents body by 2 spaces after o on condition line'
          Expect line('.') == 1
          Expect col('.') == 1
          execute "normal iif(foo == bar) {\<ESC>o "
          Expect GetPuppetIndent() == 2
          Expect getline(1) == "if(foo == bar) {"
          Expect getline(2) == '   '
          Expect line('.') == 2
          Expect col('.') == 3
        end
      end
    end

    context "multi line condition =>"
      context "body =>"
        it 'indents body by 2 spaces after hitting return'
          Expect line('.') == 1
          Expect col('.') == 1
          execute "normal iif(   foo == bar\<CR>&& baz == quux\<CR>) {\<CR> "
          Expect getline(1) == "if(   foo == bar"
          Expect getline(2) == "   && baz == quux"
          Expect getline(3) == '  ) {'
          Expect GetPuppetIndent() == 2
          Expect getline(4) == '   '
          Expect line('.') == 4
          Expect col('.') == 3
        end

        it 'indents body by 2 spaces after o on condition line'
          Expect line('.') == 1
          Expect col('.') == 1
          execute "normal iif(   foo == bar\<CR>&& baz == quux\<CR>) {\<ESC>o "
          Expect getline(1) == "if(   foo == bar"
          Expect getline(2) == "   && baz == quux"
          Expect getline(3) == '  ) {'
          Expect GetPuppetIndent() == 2
          Expect getline(4) == '   '
          Expect line('.') == 4
          Expect col('.') == 3
        end
      end
    end
  end

  context "case =>"
    context "main body =>"
      it 'indents body by 0 spaces after hitting return'
        Expect line('.') == 1
        Expect col('.') == 1
        execute "normal icase($foo) {\<CR> "
        Expect getline(1) == "case($foo) {"
        Expect GetPuppetIndent() == 0
        Expect getline(2) == ' '
        Expect line('.') == 2
        Expect col('.') == 1
      end

      it 'indents body by 0 spaces after o on condition line'
        Expect line('.') == 1
        Expect col('.') == 1
        execute "normal icase($foo) {\<ESC>o "
        Expect getline(1) == "case($foo) {"
        Expect GetPuppetIndent() == 0
        Expect getline(2) == ' '
        Expect line('.') == 2
        Expect col('.') == 1
      end

      it 'indents body by 0 spaces after hitting return on case without parentheses around variable'
        Expect line('.') == 1
        Expect col('.') == 1
        execute "normal icase $foo  {\<CR> "
        Expect getline(1) == "case $foo  {"
        Expect GetPuppetIndent() == 0
        Expect getline(2) == ' '
        Expect line('.') == 2
        Expect col('.') == 1
      end

      it 'indents closing curly brace of empty main body to opening curly brace line indent'
        Expect line('.') == 1
        Expect col('.') == 1
        execute "normal icase($foo) {\<CR>}"
        Expect getline(1) == "case($foo) {"
        Expect GetPuppetIndent() == 0
        Expect getline(2) == '}'
        Expect line('.') == 2
        Expect col('.') == 1
      end

      it 'indents closing curly brace of case body with a single case as body to column of opening curly brace'
        Expect line('.') == 1
        Expect col('.') == 1
        execute "normal icase($foo) {\<CR>'foo': {\<CR>\<CR>}\<CR>}"
        Expect getline(1) == "case($foo) {"
        Expect getline(2) == "'foo': {"
        Expect getline(3) == ''
        Expect getline(4) == '}'
        Expect GetPuppetIndent() == 0
        Expect getline(5) == '}'
        Expect line('.') == 5
        Expect col('.') == 1
      end
    end
    context "case body =>"
      it 'indents case body by 2 spaces after hitting return'
        Expect line('.') == 1
        Expect col('.') == 1
        execute "normal icase($foo) {\<CR>'foo': {\<CR> "
        Expect getline(1) == "case($foo) {"
        Expect getline(2) == "'foo': {"
        Expect GetPuppetIndent() == 2
        Expect getline(3) == '   '
        Expect line('.') == 3
        Expect col('.') == 3
      end

      it 'indents case body with list of values by 2 spaces after hitting return'
        Expect line('.') == 1
        Expect col('.') == 1
        execute "normal icase($foo) {\<CR>'foo','bar': {\<CR> "
        Expect getline(1) == "case($foo) {"
        Expect getline(2) == "'foo','bar': {"
        Expect GetPuppetIndent() == 2
        Expect getline(3) == '   '
        Expect line('.') == 3
        Expect col('.') == 3
      end

      it 'indents closing curly brace of empty case body to column of opening curly brace'
        Expect line('.') == 1
        Expect col('.') == 1
        execute "normal icase($foo) {\<CR>'foo': {\<CR>}"
        Expect getline(1) == "case($foo) {"
        Expect getline(2) == "'foo': {"
        Expect GetPuppetIndent() == 0
        Expect getline(3) == '}'
        Expect line('.') == 3
        Expect col('.') == 1
      end

      it 'indents closing curly brace of case body with an empty line as body to column of opening curly brace'
        Expect line('.') == 1
        Expect col('.') == 1
        execute "normal icase($foo) {\<CR>'foo': {\<CR>\<CR>}"
        Expect getline(1) == "case($foo) {"
        Expect getline(2) == "'foo': {"
        Expect getline(3) == ''
        Expect GetPuppetIndent() == 0
        Expect getline(4) == '}'
        Expect line('.') == 4
        Expect col('.') == 1
      end

      it 'indents closing curly brace of case body with a file resource as body to column of opening curly brace'
        Expect line('.') == 1
        Expect col('.') == 1
        execute "normal icase($foo) {\<CR>'foo': {\<CR>file { '/etc/motd':\<CR>ensure => file\<CR>, owner => root\<CR>, group => root\<CR>, mode => '644'\<CR>, content => 'Foobar'\<CR>}\<CR>}"
        Expect getline(1) == "case($foo) {"
        Expect getline(2) == "'foo': {"
        Expect getline(3) == "  file { '/etc/motd':"
        Expect getline(4) == "      ensure  => file"
        Expect getline(5) == "    , owner   => root"
        Expect getline(6) == "    , group   => root"
        Expect getline(7) == "    , mode    => '644'"
        Expect getline(8) == "    , content => 'Foobar'"
        Expect getline(9) == "  }"
        Expect GetPuppetIndent() == 0
        Expect getline(10) == '}'
        Expect line('.') == 10
        Expect col('.') == 1
      end
    end
  end

  context "class =>"
    context "parameter list =>"
      context "first parameter =>"
        it 'indents first parameter by four spaces after hitting return'
          Expect line('.') == 1
          Expect col('.') == 1
          execute "normal iclass saltfoobar(\<CR> "
          Expect getline(1) == "class saltfoobar("
          Expect GetPuppetIndent() == 4
          Expect getline(2) == '     '
          Expect line('.') == 2
          Expect col('.') == 5
        end
      end

      context "further parameters =>"
        it 'indents second parameter by two spaces after hitting return'
          Expect line('.') == 1
          Expect col('.') == 1
          execute "normal iclass saltfoobar(\<CR>$foo = bar\<CR>,"
          Expect getline(1) == "class saltfoobar("
          Expect getline(2) == '    $foo = bar'
          Expect GetPuppetIndent() == 2
          Expect getline(3) == '  ,'
          Expect line('.') == 3
          Expect col('.') == 3
        end
      end

      context "closing parenthesis =>"
        it 'indents closing parentheses by two spaces after hitting return'
          Expect line('.') == 1
          Expect col('.') == 1
          execute "normal iclass saltfoobar(\<CR>$foo = bar\<CR>, $baz = quux\<CR>) {"
          Expect getline(1) == "class saltfoobar("
          Expect getline(2) == '    $foo = bar'
          Expect getline(3) == '  , $baz = quux'
          Expect GetPuppetIndent() == 2
          Expect getline(4) == '  ) {'
          Expect line('.') == 4
          Expect col('.') == 5
        end
      end
    end
    context "body =>"
      it 'indents body by 2 spaces relative to starting line with keyword'
        Expect line('.') == 1
        Expect col('.') == 1
        execute "normal iclass saltfoobar(\<CR>$foo = bar\<CR>, $baz = quux\<CR>) {\<CR> "
        Expect getline(1) == "class saltfoobar("
        Expect getline(2) == '    $foo = bar'
        Expect getline(3) == '  , $baz = quux'
        Expect getline(4) == '  ) {'
        Expect GetPuppetIndent() == 2
        Expect getline(5) == '   '
        Expect line('.') == 5
        Expect col('.') == 3
      end
    end
    context "closing curly brace =>"
      it 'indents closing body curly brace of empty body to column of starting keyword'
        Expect line('.') == 1
        Expect col('.') == 1
        execute "normal iclass saltfoobar(\<CR>$foo = bar\<CR>, $baz = quux\<CR>) {\<CR>}"
        Expect getline(1) == "class saltfoobar("
        Expect getline(2) == '    $foo = bar'
        Expect getline(3) == '  , $baz = quux'
        Expect getline(4) == '  ) {'
        Expect GetPuppetIndent() == 0
        Expect getline(5) == '}'
        Expect line('.') == 5
        Expect col('.') == 1
      end

      it 'indents closing body curly brace of body with empty if to column of starting keyword'
        Expect line('.') == 1
        Expect col('.') == 1
        execute "normal iclass saltfoobar(\<CR>$foo = bar\<CR>, $baz = quux\<CR>) {\<CR>if($foo) {\<CR>}\<CR>}"
        Expect getline(1) == "class saltfoobar("
        Expect getline(2) == '    $foo = bar'
        Expect getline(3) == '  , $baz = quux'
        Expect getline(4) == '  ) {'
        Expect getline(5) == '  if($foo) {'
        Expect getline(6) == '  }'
        Expect GetPuppetIndent() == 0
        Expect getline(7) == '}'
        Expect line('.') == 7
        Expect col('.') == 1
      end
    end
  end

  context "defined type =>"
    context "parameter list =>"
      context "first parameter =>"
        it 'indents first parameter by four spaces after hitting return'
          Expect line('.') == 1
          Expect col('.') == 1
          execute "normal idefine saltfoobar::instance(\<CR> "
          Expect getline(1) == "define saltfoobar::instance("
          Expect GetPuppetIndent() == 4
          Expect getline(2) == '     '
          Expect line('.') == 2
          Expect col('.') == 5
        end
      end

      context "further parameters =>"
        it 'indents second parameter by two spaces after hitting return'
          Expect line('.') == 1
          Expect col('.') == 1
          execute "normal idefine saltfoobar::instance(\<CR>$foo = bar\<CR>,"
          Expect getline(1) == "define saltfoobar::instance("
          Expect getline(2) == '    $foo = bar'
          Expect GetPuppetIndent() == 2
          Expect getline(3) == '  ,'
          Expect line('.') == 3
          Expect col('.') == 3
        end
      end

      context "closing parenthesis =>"
        it 'indents closing parentheses by two spaces after hitting return'
          Expect line('.') == 1
          Expect col('.') == 1
          execute "normal idefine saltfoobar::instance(\<CR>$foo = bar\<CR>, $baz = quux\<CR>) {"
          Expect getline(1) == "define saltfoobar::instance("
          Expect getline(2) == '    $foo = bar'
          Expect getline(3) == '  , $baz = quux'
          Expect GetPuppetIndent() == 2
          Expect getline(4) == '  ) {'
          Expect line('.') == 4
          Expect col('.') == 5
        end
      end
    end
  end

  context "function =>"
    context "parameter list =>"
      context "first parameter =>"
        it 'indents first parameter by four spaces after hitting return'
          Expect line('.') == 1
          Expect col('.') == 1
          execute "normal ifunction saltfoobar::do_stuff(\<CR> "
          Expect getline(1) == "function saltfoobar::do_stuff("
          Expect GetPuppetIndent() == 4
          Expect getline(2) == '     '
          Expect line('.') == 2
          Expect col('.') == 5
        end
      end

      context "further parameters =>"
        it 'indents second parameter by two spaces after hitting return'
          Expect line('.') == 1
          Expect col('.') == 1
          execute "normal ifunction saltfoobar::do_stuff(\<CR>$foo = bar\<CR>,"
          Expect getline(1) == "function saltfoobar::do_stuff("
          Expect getline(2) == '    $foo = bar'
          Expect GetPuppetIndent() == 2
          Expect getline(3) == '  ,'
          Expect line('.') == 3
          Expect col('.') == 3
        end
      end

      context "closing parenthesis =>"
        it 'indents closing parentheses by two spaces after hitting return'
          Expect line('.') == 1
          Expect col('.') == 1
          execute "normal ifunction saltfoobar::do_stuff(\<CR>$foo = bar\<CR>, $baz = quux\<CR>) {"
          Expect getline(1) == "function saltfoobar::do_stuff("
          Expect getline(2) == '    $foo = bar'
          Expect getline(3) == '  , $baz = quux'
          Expect GetPuppetIndent() == 2
          Expect getline(4) == '  ) {'
          Expect line('.') == 4
          Expect col('.') == 5
        end
      end
    end
  end

  context "function call with code block =>"
    context "body =>"
      it 'indents body by two spaces relative to function identifier line'
        Expect line('.') == 1
        Expect col('.') == 1
        execute "normal ieach($foo) |$bar| {\<CR> "
        Expect getline(1) == "each($foo) |$bar| {"
        Expect GetPuppetIndent() == 2
        Expect getline(2) == '   '
        Expect line('.') == 2
        Expect col('.') == 3
      end
    end
  end

  context "variable assignments =>"
    it 'indents line after multi-line array value correctly'
      Expect line('.') == 1
      Expect col('.') == 1
      execute "normal i$foo = [ 'bar'\<CR>, 'baz'\<CR>]\<CR>$hello = 'world'"
      Expect getline(1) == "$foo = [ 'bar'"
      Expect getline(2) == "       , 'baz'"
      Expect getline(3) == "       ]"
      Expect GetPuppetIndent() == 0
      Expect getline(4) == "$hello = 'world'"
      Expect line('.') == 4
      Expect col('.') == 16
    end

    it 'indents line after multi-line array value with variable concat correctly'
      Expect line('.') == 1
      Expect col('.') == 1
      execute "normal i$foo = [ 'bar'\<CR>, 'baz'\<CR>] + $bar\<CR>$hello = 'world'"
      Expect getline(1) == "$foo = [ 'bar'"
      Expect getline(2) == "       , 'baz'"
      Expect getline(3) == "       ] + $bar"
      Expect GetPuppetIndent() == 0
      Expect getline(4) == "$hello = 'world'"
      Expect line('.') == 4
      Expect col('.') == 16
    end

    it 'indents line after multi-line array value with variable concat correctly even if there is an empty line in between'
      Expect line('.') == 1
      Expect col('.') == 1
      execute "normal i$foo = [ 'bar'\<CR>, 'baz'\<CR>] + $bar\<CR>\<CR>$hello = 'world'"
      Expect getline(1) == "$foo = [ 'bar'"
      Expect getline(2) == "       , 'baz'"
      Expect getline(3) == "       ] + $bar"
      Expect getline(4) == ""
      Expect GetPuppetIndent() == 0
      Expect getline(5) == "$hello = 'world'"
      Expect line('.') == 5
      Expect col('.') == 16
    end

    it 'indents line after multi-line hash value correctly'
      Expect line('.') == 1
      Expect col('.') == 1
      execute "normal i$foo = { 'bar' => 'rab'\<CR>, 'baz' => 'zab'\<CR>}\<CR>$hello = 'world'"
      Expect getline(1) == "$foo = { 'bar' => 'rab'"
      Expect getline(2) == "       , 'baz' => 'zab'"
      Expect getline(3) == "       }"
      Expect GetPuppetIndent() == 0
      Expect getline(4) == "$hello = 'world'"
      Expect line('.') == 4
      Expect col('.') == 16
    end
  end
end
