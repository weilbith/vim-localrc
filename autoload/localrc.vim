let s:cache_file_separator = ':'


function! localrc#find_configuration_files(base_path) abort
  " Determine if the base is a file or a directory
  if filereadable(a:base_path)
    let l:directory = fnamemodify(a:base_path, ':h')
  else
    if isdirectory(a:base_path)
      let l:directory = a:base_path
    else
      " TODO: Make it a proper error
      echom 'error determine base path to find configuration files'
      return
    endif
  endif

  let l:rc_file_list = []

  " Traverse directories upwards until reach configured top.
  " Watch-out for local configurations files on each step.
  while l:directory =~ get(g:, 'localrc_top_dir', $HOME)
    for l:file_name in get(g:, 'localrc_file_name_list', ['.vimrc', '.exrc'])
      let l:rc_file_candidate = globpath(l:directory, l:file_name)

      if filereadable(l:rc_file_candidate)
        call add(l:rc_file_list, l:rc_file_candidate)
      endif
    endfor

    let l:directory = fnamemodify(l:directory, ':h')
  endwhile

  return l:rc_file_list
endfunction

function! localrc#calculate_file_hash(file) abort
  let l:file_absolute_path = fnamemodify(a:file, ':p')

  if !filereadable(l:file_absolute_path)
    " TODO: Make it a proper error
    echom 'Error: Can not calculate hash of not existing file'
    return
  endif

  let l:hash_command = get(g:, 'localrc_hash_command', 'sha1sum') . ' ' . l:file_absolute_path
  let l:command_output = system(l:hash_command)
  let l:hash_value = split(l:command_output, ' ')[get(g:, 'localrc_hash_command_word_index', 0)]

  return l:hash_value
endfunction

function! localrc#get_cache_file() abort
  let l:xdg_cache_home = getenv('XDG_CACHE_HOME') ? $XDG_CACHE_HOME : $HOME . '/' . '.cache'
  let l:chache_file = get(g:, 'localrc#cache_file', l:xdg_cache_home . '/vim-localrc/hashes')

  if !filereadable(l:chache_file)
    echom 'Create new localrc cache file "' . l:chache_file .'"'
    call mkdir(fnamemodify(l:chache_file, ':h'), 'p')
    call writefile([], l:chache_file, 'b')
  endif

  return l:chache_file
endfunction

function! localrc#get_confirmation_state(file) abort
  let l:file_absolute_path = fnamemodify(a:file, ':p')
  let l:chache_file = localrc#get_cache_file()
  let l:file_hash_now = localrc#calculate_file_hash(l:file_absolute_path)

  let l:confirmation_state = {
        \   'seen_before': v:false,
        \   'confirmed': v:false
        \ }

  for l:line in readfile(l:chache_file, '\n')
    if strlen(l:line) == 0 | continue | endif

    let l:entry = split(l:line, s:cache_file_separator)
    let l:file_path = l:entry[0]
    let l:file_hash = l:entry[1]

    if l:file_path ==# l:file_absolute_path
      let l:confirmation_state.seen_before = v:true

      if l:file_hash ==# l:file_hash_now
        let l:confirmation_state.confirmed = v:true
        break
      endif
    endif
  endfor

  return l:confirmation_state
endfunction

function! localrc#cache_confirmation(file) abort
  if !localrc#is_rc_file(a:file) | return | endif
  let l:file_absolute_path = fnamemodify(a:file, ':p')
  let l:file_hash_now = localrc#calculate_file_hash(l:file_absolute_path)
  let l:cache_file = localrc#get_cache_file()
  let l:new_entry = l:file_absolute_path . s:cache_file_separator . l:file_hash_now
  call writefile([l:new_entry], l:cache_file, 'a')
endfunction

function! localrc#source_rc_file(file) abort
  if !filereadable(a:file)
    " TODO: Throw actual error
    echom 'Error: Can not import not existing configuration file "' . a:file .'"'
    return
  endif

  let l:file_absolute_path = fnamemodify(a:file, ':p')
  let l:confirmation_state = localrc#get_confirmation_state(l:file_absolute_path)
  let l:source_file = v:false
  let l:cache_confirmation = v:false

  if l:confirmation_state.confirmed
    let l:source_file = v:true

  else
    echo 'Attempt to source local runtime configuration.'

    if l:confirmation_state.seen_before
      echo 'The file has changed since the last confirmation!'
    else
      echo 'The file has never been permanently confirmed before!'
    endif

    let l:choice = confirm('Source "' . l:file_absolute_path . '"?', "Yes\nOnce\nNo\nAbort", 3)

    if l:choice == 0 || l:choice == 4 | return | endif
    if l:choice == 1 || l:choice == 2 | let l:source_file = v:true | endif
    if l:choice == 1 | let l:cache_confirmation = v:true | endif
  endif

  if l:source_file | exec 'source ' . l:file_absolute_path | endif
  if l:cache_confirmation | call localrc#cache_confirmation(a:file) | endif
endfunction

function! localrc#is_rc_file(file) abort
  for l:file_name in get(g:, 'localrc_file_name_list', ['.vimrc', '.exrc'])
    if fnamemodify(a:file, ':t') ==# l:file_name | return v:true | endif
  endfor

  return v:false
endfunction

function! localrc#apply_local_configurations(base) abort
  " Do not apply for local configuration files to avoid endless loops
  if localrc#is_rc_file(a:base) | return | endif

  let l:rc_file_list = localrc#find_configuration_files(a:base)

  for l:rc_file in l:rc_file_list
    call localrc#source_rc_file(l:rc_file)
  endfor
endfunction
