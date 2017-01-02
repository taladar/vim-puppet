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

  context "starting unindented =>"
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
  end

  context "starting indented by 4 spaces =>"
    context "resources =>"
      context "with title string =>"
        context "first parameter =>"
          it 'indents by 4 spaces on return after a resource start'
            execute "normal i    \<ESC>"
            Expect line('.') == 1
            Expect col('.') == 4
            execute "normal Afoo { 'bar':\<CR> "
            Expect GetPuppetIndent() == 8
            Expect getline(1) == "    foo { 'bar':"
            Expect getline(2) == '         '
            Expect line('.') == 2
            Expect col('.') == 9
          end

          it 'indents by 4 spaces on o on resource start line'
            execute "normal i    \<ESC>"
            Expect line('.') == 1
            Expect col('.') == 4
            execute "normal Afoo { 'bar':\<ESC>o "
            Expect GetPuppetIndent() == 8
            Expect getline(1) == "    foo { 'bar':"
            Expect getline(2) == '         '
            Expect line('.') == 2
            Expect col('.') == 9
          end
        end

        context "further parameters =>"
          it 'indents comma by 2 spaces on return after initial parameter of resource'
            execute "normal i    \<ESC>"
            Expect line('.') == 1
            Expect col('.') == 4
            execute "normal Afoo { 'bar':\<CR>hello => world\<CR>, baz"
            Expect GetPuppetIndent() == 6
            Expect getline(1) == "    foo { 'bar':"
            Expect getline(3) == '      , baz'
            Expect line('.') == 3
            Expect col('.') == 11
          end
        end

        context "closing brace =>"
          it 'unindents the closing curly brace in a parameter-less resource'
            execute "normal i    \<ESC>"
            Expect line('.') == 1
            Expect col('.') == 4
            execute "normal Afoo { 'bar':\<CR>}"
            Expect GetPuppetIndent() == 4
            Expect getline(1) == "    foo { 'bar':"
            Expect getline(2) == '    }'
            Expect line('.') == 2
            Expect col('.') == 5
          end

          it 'unindents the closing curly brace in a single parameter resource'
            execute "normal i    \<ESC>"
            Expect line('.') == 1
            Expect col('.') == 4
            execute "normal Afoo { 'bar':\<CR>hello => world\<CR>}"
            Expect GetPuppetIndent() == 4
            Expect getline(1) == "    foo { 'bar':"
            Expect getline(3) == '    }'
            Expect line('.') == 3
            Expect col('.') == 5
          end

          it 'unindents the closing curly brace in a two parameter resource'
            execute "normal i    \<ESC>"
            Expect line('.') == 1
            Expect col('.') == 4
            execute "normal Afoo { 'bar':\<CR>hello => world\<CR>, foo => bar\<CR>}"
            Expect GetPuppetIndent() == 4
            Expect getline(1) == "    foo { 'bar':"
            Expect getline(4) == '    }'
            Expect line('.') == 4
            Expect col('.') == 5
          end
        end
      end

      context "with title array =>"
        context "title array =>"
          it 'indents a comma after opening resource title array to open square bracket column'
            execute "normal i    \<ESC>"
            Expect line('.') == 1
            Expect col('.') == 4
            execute "normal Afoo { [ 'bar'\<CR>,"
            Expect GetPuppetIndent() == 10
            Expect getline(1) == "    foo { [ 'bar'"
            Expect getline(2) == '          ,'
            Expect line('.') == 2
            Expect col('.') == 11
          end

          it 'indents a comma later in resource title array to previous line comma'
            execute "normal i    \<ESC>"
            Expect line('.') == 1
            Expect col('.') == 4
            execute "normal Afoo { [ 'bar'\<CR>, 'baz'\<CR>,"
            Expect GetPuppetIndent() == 10
            Expect getline(1) == "    foo { [ 'bar'"
            Expect getline(2) == "          , 'baz'"
            Expect getline(3) == '          ,'
            Expect line('.') == 3
            Expect col('.') == 11
          end

          it 'indents a closing square bracket after opening resource title array to open square bracket column'
            execute "normal i    \<ESC>"
            Expect line('.') == 1
            Expect col('.') == 4
            execute "normal Afoo { [ 'bar'\<CR>]"
            Expect GetPuppetIndent() == 10
            Expect getline(1) == "    foo { [ 'bar'"
            Expect getline(2) == '          ]'
            Expect line('.') == 2
            Expect col('.') == 11
          end

          it 'indents a closing square bracket later in resource title array to open square bracket column'
            execute "normal i    \<ESC>"
            Expect line('.') == 1
            Expect col('.') == 4
            execute "normal Afoo { [ 'bar'\<CR>, 'baz'\<CR>]"
            Expect GetPuppetIndent() == 10
            Expect getline(1) == "    foo { [ 'bar'"
            Expect getline(3) == '          ]'
            Expect line('.') == 3
            Expect col('.') == 11
          end
        end

        context "first parameter =>"
          it 'indents the first line after closing square bracket of resource title array to resource name + 4'
            execute "normal i    \<ESC>"
            Expect line('.') == 1
            Expect col('.') == 4
            execute "normal Afoo { [ 'bar'\<CR>, 'baz'\<CR>]:\<CR>foo"
            Expect GetPuppetIndent() == 8
            Expect getline(1) == "    foo { [ 'bar'"
            Expect getline(4) == '        foo'
            Expect line('.') == 4
            Expect col('.') == 11
          end
        end

        context "further parameters =>"
          it 'indents second line after closing square bracket of resource title array to resource name + 2'
            execute "normal i    \<ESC>"
            Expect line('.') == 1
            Expect col('.') == 4
            execute "normal Afoo { [ 'bar'\<CR>, 'baz'\<CR>]:\<CR>foo => bar\<CR>, baz"
            Expect GetPuppetIndent() == 6
            Expect getline(1) == "    foo { [ 'bar'"
            Expect getline(5) == '      , baz'
            Expect line('.') == 5
            Expect col('.') == 11
          end

          it 'indents third line after closing square bracket of resource title array to resource name + 2'
            execute "normal i    \<ESC>"
            Expect line('.') == 1
            Expect col('.') == 4
            execute "normal Afoo { [ 'bar'\<CR>, 'baz'\<CR>]:\<CR>foo => bar\<CR>, baz => quux\<CR>, hello"
            Expect GetPuppetIndent() == 6
            Expect getline(1) == "    foo { [ 'bar'"
            Expect getline(6) == '      , hello'
            Expect line('.') == 6
            Expect col('.') == 13
          end
        end

        context "closing brace =>"
          it 'unindents the closing curly brace in a parameter-less resource with title array'
            execute "normal i    \<ESC>"
            Expect line('.') == 1
            Expect col('.') == 4
            execute "normal Afoo { [ 'bar'\<CR>, 'baz'\<CR>]:\<CR>}"
            Expect GetPuppetIndent() == 4
            Expect getline(1) == "    foo { [ 'bar'"
            Expect getline(4) == '    }'
            Expect line('.') == 4
            Expect col('.') == 5
          end

          it 'unindents the closing curly brace in a single parameter resource with title array'
            execute "normal i    \<ESC>"
            Expect line('.') == 1
            Expect col('.') == 4
            execute "normal Afoo { [ 'bar'\<CR>, 'baz'\<CR>]:\<CR>foo => bar\<CR>}"
            Expect GetPuppetIndent() == 4
            Expect getline(1) == "    foo { [ 'bar'"
            Expect getline(5) == '    }'
            Expect line('.') == 5
            Expect col('.') == 5
          end

          it 'unindents the closing curly brace in a two parameter resource with title array'
            execute "normal i    \<ESC>"
            Expect line('.') == 1
            Expect col('.') == 4
            execute "normal Afoo { [ 'bar'\<CR>, 'baz'\<CR>]:\<CR>foo => bar\<CR>, baz => quux\<CR>}"
            Expect GetPuppetIndent() == 4
            Expect getline(1) == "    foo { [ 'bar'"
            Expect getline(6) == '    }'
            Expect line('.') == 6
            Expect col('.') == 5
          end
        end
      end
    end
  end
end
