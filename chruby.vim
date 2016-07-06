" based on https://github.com/tpope/vim-rvm/blob/master/plugin/rvm.vim

if exists('g:loaded_chruby')
  finish
endif

if !exists('$rubies_path') && isdirectory(expand('~/.rubies'))
    let $rubies_path = expand('~/.rubies')
end

let g:loaded_chruby = 1

function! s:ChangeVersion(new_version)
    echo a:new_version
    let gem_path = expand("~/.gem/ruby/.*./bin")
    let rubies_gem_path = expand("~/.rubies/ruby-.*./lib/ruby/gems/.*./bin")
    let rubies_path = expand("~/.rubies/ruby-.*./bin")

    let updated_path = []

    " remove all ruby specific paths
    for dir in split($PATH, ":")
        if matchstr(dir, gem_path) == '' &&
            \ matchstr(dir, rubies_gem_path) == '' &&
            \ matchstr(dir, rubies_path) == ''
                call add(updated_path, dir)
        endif
    endfor

    let updated_gem_path = expand("~/.gem/ruby/" . a:new_version . "/bin")
    let updated_rubies_gem_path = expand("~/.rubies/ruby-" . a:new_version ."/lib/ruby/gems/" . a:new_version ."/bin")
    let updated_rubies_path = expand("~/.rubies/ruby-" . a:new_version ."/bin")

    let $PATH = join([updated_gem_path,
                \ updated_rubies_gem_path,
                \ updated_rubies_path] + updated_path, ':')

    echo $PATH
endfunction

function! s:VersionList(A,L,P) abort
    return split(system('ls ~/.gem/ruby/ | xargs'))
endfunction

command! -nargs=? -complete=customlist,s:VersionList Chruby :execute s:ChangeVersion(<f-args>)
