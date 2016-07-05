" based on https://github.com/tpope/vim-rvm/blob/master/plugin/rvm.vim

if !exists('$rubies_path') && isdirectory(expand('~/.rubies'))
    let $rubies_path = expand('~/.rubies')
end

let g:loaded_chruby = 1

" TODO split out path by : delimiter
" TODO find if .rubies directory is already contains in path
"
" 2.1.2 using chruby:
" /Users/Michael/.gem/ruby/2.1.2/bin:/Users/Michael/.rubies/ruby-2.1.2/lib/ruby/gems/2.1.0/bin:/Users/Michael/.rubies/ruby-2.1.2/bin:/Users/Michael/miniconda/bin:/Users/Michael/survival-kit/bin:/opt/bin:/usr/local/bin:/usr/local/share/python:/usr/local/opt/go/libexec/bin:/usr/bin:/bin:/usr/sbin:/sbin
" 2.2.0 using chruby:
" /Users/Michael/.gem/ruby/2.2.0/bin:/Users/Michael/.rubies/ruby-2.2.0/lib/ruby/gems/2.2.0/bin:/Users/Michael/.rubies/ruby-2.2.0/bin:/Users/Michael/miniconda/bin:/Users/Michael/survival-kit/bin:/opt/bin:/usr/local/bin:/usr/local/share/python:/usr/local/opt/go/libexec/bin:/usr/bin:/bin:/usr/sbin:/sbin
" using system ruby:
" /Users/Michael/miniconda/bin:/Users/Michael/survival-kit/bin:/opt/bin:/usr/local/bin:/usr/local/share/python:/usr/local/opt/go/libexec/bin:/usr/bin:/bin:/usr/sbin:/sbin
"
" /opt/rubies and .rubies are the default locations

"--------------------------------------------------------------------------------

" 3 directories to add

" find existing directory, replace it or add to the front
"
" cycle all paths, split on :

" echo split($PATH, ":")
"
" iterate, find positions of 3 paths
" for each
"   if found, replace the version number
"   else add a new path for the version you want to use

let gem_path = expand("~/.gem/ruby/2.1.3/bin")
let rubies_gem_path = expand("~/.rubies/ruby-2.1.3/lib/ruby/gems/2.1.3/bin")
let rubies_path = expand("~/.rubies/ruby-2.1.3/lib/ruby/bin")

let new_path = []
" remove all the matches
for dir in split($PATH, ":")
    if matchstr(dir, expand("~/.gem/ruby/2.3.1/bin")) == '' &&
                \ matchstr(dir, expand("/home/mikepjb/.rubies/ruby-2.3.1/lib/ruby/gems/2.3.0/bin")) == '' &&
                \ matchstr(dir, expand("/home/mikepjb/.rubies/ruby-2.3.1/bin")) == ''
        " found a path we don't want to include, do nothing
        echo 'match!'
    else
        " add to the new path
        call add(new_path, dir)
    endif
    echo dir
endfor

echo join(new_path, ':')
" place all the paths at the beginning of the PATH
