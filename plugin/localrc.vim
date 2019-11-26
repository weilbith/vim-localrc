augroup LocalrcPlugin
  autocmd!
  autocmd BufReadPost *
        \ if get(g:, 'localrc_load_automatically', v:true) |
        \   call localrc#apply_local_configurations(expand('<afile>:p')) |
        \ endif

  autocmd BufWritePost *
        \ if get(g:, 'localrc_confirm_automatically', v:true) |
        \   call localrc#cache_confirmation(expand('<afile>:p')) |
        \ endif
augroup END
