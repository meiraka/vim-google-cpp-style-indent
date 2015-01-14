if exists('b:did_indent')
  finish
endif


setlocal autoindent
setlocal cindent
setlocal indentexpr=GetCppIndent()
setlocal indentkeys=!^F,o,O,},:
setlocal expandtab
setlocal tabstop<
setlocal softtabstop=2
setlocal shiftwidth=2
setlocal cinoptions=l1,g1,h1,N-s,p2,t0,i0,+4,(0,u0,w1,W4,)1000,*1000

let b:undo_indent = 'setlocal '.join([
\   'autoindent<',
\   'cindent<',
\   'indentexpr<',
\   'indentkeys<',
\   'expandtab<',
\   'tabstop<',
\   'softtabstop<',
\   'shiftwidth<',
\   'cinoptions<',
\ ])

function! FindBefore(pattern, lineno)
    let findline = a:lineno
    while findline > 1
        if getline(findline) =~# a:pattern
            return findline
        endif
        let findline = prevnonblank(findline - 1)
    endwhile
    return findline
endfunction

function! GetCppIndent()
    let prev_line = prevnonblank(v:lnum - 1)

    " The content of a namespace is not indented
    "
    " namespace {
    " const int foo = 10;
    " }
    " cinoptions=nN does not effect in vim 7.2 or earlier
    if v:version < 703
        if getline(prev_line) =~# '\v^\s*namespace\s*[^\{]*\{\s*'
            return indent(prev_line)
        endif
    endif

    " Four spaces for constructor initializer lists
    "
    " Foo::Foo() : foo(1), bar(2), buzz(3) {
    "   init();
    " }
    "
    " Foo::Foo()
    "     : foo(1),
    "       bar(2),
    "       buzz(3) {
    "   init();
    " }

    " continued constructor
    if getline(prev_line) =~# '\v\s*[^:]+::[^\)]*\)\s*$'
        return indent(prev_line) + &l:shiftwidth * 2
    endif

    " continued initializer
    if getline(prev_line) =~# '\v\s*:[^:][^,]+,\s*$'
        return indent(prev_line) + &l:shiftwidth
    endif

    " end of initializer
    if getline(prev_line) =~# '\v[^\)]+\)\s*\{\s*$'
        " find fist constructor line 
        let before_line = prevnonblank(prev_line - 1)
        let constructor_line = FindBefore('\v\s*[^:]+::[^\)]*\)\s*$', before_line)
        let rightcurlybrace_line = FindBefore('{', before_line)
        " check prev_line left brace is constructor's brace
        if constructor_line > rightcurlybrace_line
            return indent(constructor_line) + &l:shiftwidth
        endif
    endif

    " end of constructor
    if getline(v:lnum) =~# '\v^\s*\}$'
        return indent(prev_line) - &l:shiftwidth
    endif

    " apply cindent other indent
    return cindent(v:lnum)
endfunction

let b:did_indent = 1
