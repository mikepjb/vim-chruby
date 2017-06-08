scriptencoding utf-8 

" Find supported Ruby versions from $rubies_path with glob |> filter.
function! chruby#rubies() abort
  let l:rubies = glob($rubies_path . '/*', v:true, v:true)
  let l:rubies = filter(l:rubies, 'isdirectory(v:val)')
  return l:rubies
endfunction

" Find and read the nearest `.ruby-version` file (upwards traversal).
function! chruby#find_ruby_version() abort
  let l:ruby_version = findfile('.ruby-version', '.;')
  if len(l:ruby_version)
    return readfile(l:ruby_version)[0]
  endif
  return ''
endfunction

" Remove any environment variables set by chruby or by chruby#use. This
" implementation matches the implementation in chruby itself but uses native
" vim functions for removing matching patterns.
"
" This modified `$PATH`, `$RUBY_ROOT`, `$RUBY_ENGINE`, `$RUBY_VERSION`, and
" `$RUBYOPT`. It will usually modify `$GEM_HOME`, `$GEM_ROOT`, and `$GEM_PATH`
" (but only if the current user is not a root user).
"
" This does nothing if `$RUBY_ROOT` is unset or empty.
function! chruby#reset() abort
  if !len(chruby#root())
    return v:true
  endif

  let l:path = chruby#clear(chruby#cxs($PATH), chruby#root('bin'))

  if s:uid != 0
    let l:gem_path = chruby#cxs($GEM_PATH)

    if len(chruby#gem_home())
      let l:path = chruby#clear(l:path, chruby#gem_home('bin'))
      let l:gem_path = chruby#clear(l:gem_path, chruby#gem_home())
    endif

    if len(chruby#gem_root())
      let l:path = chruby#clear(l:path, chruby#gem_root('bin'))
      let l:gem_path = chruby#clear(l:gem_path, chruby#gem_root())
    endif

    let $GEM_HOME = ''
    let $GEM_ROOT = ''
    let $GEM_PATH = chruby#cxe(l:gem_path)
  endif

  let $RUBY_ROOT = ''
  let $RUBY_ENGINE = ''
  let $RUBY_VERSION = ''
  let $RUBYOPT = ''
  let $PATH = chruby#cxe(l:path)
endfunction

" Use the specified `a:path` Ruby version and set `$RUBYOPT` from `a:rubyopt`.
" Calls `chruby#reset` first. This will set `$RUBY_ROOT`, `$RUBYOPT`, `$PATH`,
" `$RUBY_ENGINE`, `$RUBY_VERSION`, and `$GEM_ROOT`. It will usually set
" `$GEM_HOME` and `GEM_PATH` (but only if the current user is not a root user).
"
" If `a:path/bin/ruby` is not executable, an error is printed.
function! chruby#use(path, rubyopt) abort
  if !executable(a:path . '/bin/ruby')
    echoerr 'chruby: ' . a:path . '/bin/ruby is not executable'
    return v:false
  endif

  if len($RUBY_ROOT)
    call chruby#reset()
  endif

  let $RUBY_ROOT = a:path
  let $RUBYOPT = a:rubyopt
  let $PATH = $RUBY_ROOT . '/bin:' . $PATH

  let $RUBY_ENGINE = chruby#print('defined?(RUBY_ENGINE) ? RUBY_ENGINE : %q(ruby)')
  let $RUBY_VERSION = chruby#print('RUBY_VERSION')

  let l:gem_root = chruby#print('begin; require %q(rubygems); print Gem.default_dir; rescue LoadError; end')
  if len(l:gem_root)
    let $GEM_ROOT = l:gem_root
  endif

  if s:uid != 0
    let $GEM_HOME = join([ $HOME, '.gem', $RUBY_ENGINE, $RUBY_VERSION], '/')

    let l:gem_path = $GEM_PATH
    let $GEM_PATH = $GEM_HOME
    if len(l:gem_root)
      let $GEM_PATH = $GEM_PATH . ':' . $GEM_ROOT
      let $PATH = $GEM_ROOT . '/bin:' . $PATH
    endif
    if len(l:gem_path)
      let $GEM_PATH = $GEM_PATH . ':' . l:gem_path
    endif

    let $PATH = $GEM_HOME . '/bin:' . $PATH
  endif

  return v:true
endfunction

function! chruby#do(bang, ...) abort
  if a:bang ==# '!'
    return chruby#match('auto')
  else
    return call('chruby#match', a:000)
  endif
endfunction

" The core functionality of `:Chruby`.
"
" If a version is provided as the first argument, that version will be used to
" set the Chruby version.
"
" - The special version `system` calls `chruby#reset` to go back to the system
"   Ruby.
" - The special version `auto` calls `chruby#find_ruby_version` to find the
"   nearest `.ruby-version` file and use that version.
"
" If the version does not match known rubies, an error message will be printed.
" A matching version will call `chruby#use`.
function! chruby#match(...) abort
  if a:0 && len(a:1)
    let l:version = a:1
  else
    let l:rubies = chruby#rubies()
    for l:version in chruby#rubies()
      let l:star = ' '
      if l:version == $RUBY_ROOT | let l:star = '*' | endif
      echo ' ' . l:star . ' ' . fnamemodify(l:version, ':t')
    endfor
    return v:true
  endif

  if l:version ==# 'system'
    call chruby#reset()
    return v:true
  endif

  if l:version ==# 'auto'
    let l:version = chruby#find_ruby_version()
  endif

  let l:rubies = chruby#rubies()
  let l:index = match(l:rubies, '^' . l:version . '$')

  if l:index == -1
    let l:index = match(l:rubies, l:version)
  endif

  if l:index == -1
    echoerr 'chruby: unknown Ruby ' . l:version
    return v:false
  endif

  return chruby#use(l:rubies[l:index], a:0 > 1 ? a:2 : '')
endfunction

" Command completion function that shows chruby#rubies() plus `system` and
" `auto`.
function! chruby#rubies_list(A, L, P) abort
  return extend(map(chruby#rubies(), 'fnamemodify(v:val, '':t'')'), [ 'system', 'auto' ])
endfunction

if !exists('s:uid')
  let s:uid = systemlist('id -u')[0] + 0
endif

if !exists('$rubies_path') && isdirectory(expand('~/.rubies'))
  let $rubies_path = expand('~/.rubies')
end

" ---- Utility functions

" Returns a computed path. Used by `chruby#root`, `chruby#gem_home`, and
" `chruby#gem_root`.
function! chruby#path(path, ...) abort
  let l:path = a:path
  if a:0 > 0
    let l:parts = join(a:000, '/')
    let l:path = join([ l:path, l:parts ], '/')
  endif
  return l:path
endfunction

" Returns `$RUBY_ROOT`, or if parameters are provided, a path relative to
" `$RUBY_ROOT`.
"
"   chruby#root('bin') => $RUBY_ROOT . '/bin'
function! chruby#root(...) abort
  return call('chruby#path', extend([$RUBY_ROOT], a:000))
endfunction

" Returns `$GEM_HOME`, or if parameters are provided, a path relative to
" `$GEM_HOME`.
"
"   chruby#gem_home('bin') => $GEM_HOME . '/bin
function! chruby#gem_home(...) abort
  return call('chruby#path', extend([$GEM_HOME], a:000))
endfunction

" Returns `$GEM_ROOT`, or if parameters are provided, a path relative to
" `$GEM_ROOT`.
"
"   chruby#gem_root('bin') => $GEM_ROOT . '/bin
function! chruby#gem_root(...) abort
  return call('chruby#path', extend([$GEM_ROOT], a:000))
endfunction

" Makes `a:expr` safe for `chruby#clear`. Use before calling `chruby#clear`.
function! chruby#cxs(expr) abort
  return ':' . a:expr . ':'
endfunction

" Makes `a:expr` unsafe for `chruby#clear`. Use after calling `chruby#clear`.
function! chruby#cxe(expr) abort
  return substitute(substitute(a:expr, '^:', '', ''), ':$', '', '')
endfunction

" Safely removes `a:path` from `a:expr`. Use after calling `chruby#cxs` and
" before calling `chruby#cxe`.
function! chruby#clear(expr, path) abort
  return substitute(a:expr, chruby#cxs(a:path), ':', 'g')
endfunction

" Run a `print` statement for `a:expr` using `$RUBY_ROOT/bin/ruby`.
function! chruby#print(expr) abort
  return system(chruby#root('bin', 'ruby') . ' -e "print ' . a:expr . '"')
endfunction
