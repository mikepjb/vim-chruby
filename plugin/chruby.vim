" based on https://github.com/tpope/vim-rvm/blob/master/plugin/rvm.vim

if exists('g:loaded_chruby')
  finish
endif

let g:loaded_chruby = 1

command! -bang -nargs=? -complete=customlist,chruby#rubies_list
      \ Chruby :call chruby#do('<bang>', <f-args>)

if exists('g:chruby_autoload')
  augroup __chruby-autoload
    autocmd!
    autocmd VimEnter * call chruby#match('auto')
  augroup END
endif
