let s:is_vim = !has('nvim')
let s:is_win = has('win32') || has('win64')
let s:is_mac = has('mac')
let s:sign_api = exists('*sign_getplaced') && exists('*sign_place')
let s:sign_groups = []
let s:outline_preview_bufnr = 0

" Check <Tab> and <CR>
function! coc#ui#check_pum_keymappings(trigger) abort
  if a:trigger !=# 'none'
    for key in ['<cr>', '<tab>', '<c-y>', '<s-tab>']
      let arg = maparg(key, 'i', 0, 1)
      if get(arg, 'expr', 0)
        let rhs = get(arg, 'rhs', '')
        if rhs =~# '\<pumvisible()' && rhs !~# '\<coc#pum#visible()'
          let rhs = substitute(rhs, '\Cpumvisible()', 'coc#pum#visible()', 'g')
          let rhs = substitute(rhs, '\c"\\<C-n>"', 'coc#pum#next(1)', '')
          let rhs = substitute(rhs, '\c"\\<C-p>"', 'coc#pum#prev(1)', '')
          let rhs = substitute(rhs, '\c"\\<C-y>"', 'coc#pum#confirm()', '')
          execute 'inoremap <silent><nowait><expr> '.arg['lhs'].' '.rhs
        endif
      endif
    endfor
  endif
endfunction

function! coc#ui#quickpick(title, items, cb) abort
  if exists('*popup_menu')
    function! s:QuickpickHandler(id, result) closure
      call a:cb(v:null, a:result)
    endfunction
    function! s:QuickpickFilter(id, key) closure
      for i in range(1, len(a:items))
        if a:key == string(i)
          call popup_close(a:id, i)
          return 1
        endif
      endfor
      " No shortcut, pass to generic filter
      return popup_filter_menu(a:id, a:key)
    endfunction
    try
      call popup_menu(a:items, {
        \ 'title': a:title,
        \ 'filter': function('s:QuickpickFilter'),
        \ 'callback': function('s:QuickpickHandler'),
        \ })
      redraw
    catch /.*/
      call a:cb(v:exception)
    endtry
  else
    let res = inputlist([a:title] + a:items)
    call a:cb(v:null, res)
  endif
endfunction

" cmd, cwd
function! coc#ui#open_terminal(opts) abort
  if s:is_vim && !exists('*term_start')
    echohl WarningMsg | echon "Your vim doesn't have terminal support!" | echohl None
    return
  endif
  if get(a:opts, 'position', 'bottom') ==# 'bottom'
    let p = '5new'
  else
    let p = 'vnew'
  endif
  execute 'belowright '.p.' +setl\ buftype=nofile '
  setl buftype=nofile
  setl winfixheight
  setl norelativenumber
  setl nonumber
  setl bufhidden=wipe
  if exists('#User#CocTerminalOpen')
    exe 'doautocmd <nomodeline> User CocTerminalOpen'
  endif
  let cmd = get(a:opts, 'cmd', '')
  let autoclose = get(a:opts, 'autoclose', 1)
  if empty(cmd)
    throw 'command required!'
  endif
  let cwd = get(a:opts, 'cwd', getcwd())
  let keepfocus = get(a:opts, 'keepfocus', 0)
  let bufnr = bufnr('%')
  let Callback = get(a:opts, 'Callback', v:null)

  function! s:OnExit(status) closure
    let content = join(getbufline(bufnr, 1, '$'), "\n")
    if a:status == 0 && autoclose == 1
      execute 'silent! bd! '.bufnr
    endif
    if !empty(Callback)
      call call(Callback, [a:status, bufnr, content])
    endif
  endfunction

  if has('nvim')
    call termopen(cmd, {
          \ 'cwd': cwd,
          \ 'on_exit': {job, status -> s:OnExit(status)},
          \})
  else
    if s:is_win
      let cmd = 'cmd.exe /C "'.cmd.'"'
    endif
    call term_start(cmd, {
          \ 'cwd': cwd,
          \ 'exit_cb': {job, status -> s:OnExit(status)},
          \ 'curwin': 1,
          \})
  endif
  if keepfocus
    wincmd p
  endif
  return bufnr
endfunction

" run command in terminal
function! coc#ui#run_terminal(opts, cb)
  let cmd = get(a:opts, 'cmd', '')
  if empty(cmd)
    return a:cb('command required for terminal')
  endif
  let opts = {
        \ 'cmd': cmd,
        \ 'cwd': get(a:opts, 'cwd', getcwd()),
        \ 'keepfocus': get(a:opts, 'keepfocus', 0),
        \ 'Callback': {status, bufnr, content -> a:cb(v:null, {'success': status == 0 ? v:true : v:false, 'bufnr': bufnr, 'content': content})}
        \}
  call coc#ui#open_terminal(opts)
endfunction

function! coc#ui#echo_hover(msg)
  echohl MoreMsg
  echo a:msg
  echohl None
  let g:coc_last_hover_message = a:msg
endfunction

function! coc#ui#echo_messages(hl, msgs)
  if a:hl !~# 'Error' && (mode() !~# '\v^(i|n)$')
    return
  endif
  let msgs = filter(copy(a:msgs), '!empty(v:val)')
  if empty(msgs)
    return
  endif
  execute 'echohl '.a:hl
  echo join(msgs, "\n")
  echohl None
endfunction

function! coc#ui#preview_info(lines, filetype, ...) abort
  pclose
  keepalt new +setlocal\ previewwindow|setlocal\ buftype=nofile|setlocal\ noswapfile|setlocal\ wrap [Document]
  setl bufhidden=wipe
  setl nobuflisted
  setl nospell
  exe 'setl filetype='.a:filetype
  setl conceallevel=0
  setl nofoldenable
  for command in a:000
    execute command
  endfor
  call append(0, a:lines)
  exe "normal! z" . len(a:lines) . "\<cr>"
  exe "normal! gg"
  wincmd p
endfunction

function! coc#ui#open_files(files)
  let bufnrs = []
  " added on latest vim8
  if exists('*bufadd') && exists('*bufload')
    for file in a:files
      let file = fnamemodify(file, ':.')
      if bufloaded(file)
        call add(bufnrs, bufnr(file))
      else
        let bufnr = bufadd(file)
        call bufload(file)
        call add(bufnrs, bufnr)
        call setbufvar(bufnr, '&buflisted', 1)
      endif
    endfor
  else
    noa keepalt 1new +setl\ bufhidden=wipe
    for file in a:files
      let file = fnamemodify(file, ':.')
      execute 'noa edit +setl\ bufhidden=hide '.fnameescape(file)
      if &filetype ==# ''
        filetype detect
      endif
      call add(bufnrs, bufnr('%'))
    endfor
    noa close
  endif
  doautocmd BufEnter
  return bufnrs
endfunction

function! coc#ui#echo_lines(lines)
  echo join(a:lines, "\n")
endfunction

function! coc#ui#echo_signatures(signatures) abort
  if pumvisible() | return | endif
  echo ""
  for i in range(len(a:signatures))
    call s:echo_signature(a:signatures[i])
    if i != len(a:signatures) - 1
      echon "\n"
    endif
  endfor
endfunction

function! s:echo_signature(parts)
  for part in a:parts
    let hl = get(part, 'type', 'Normal')
    let text = get(part, 'text', '')
    if !empty(text)
      execute 'echohl '.hl
      execute "echon '".substitute(text, "'", "''", 'g')."'"
      echohl None
    endif
  endfor
endfunction

function! coc#ui#iterm_open(dir)
  return s:osascript(
      \ 'if application "iTerm2" is not running',
      \   'error',
      \ 'end if') && s:osascript(
      \ 'tell application "iTerm2"',
      \   'tell current window',
      \     'create tab with default profile',
      \     'tell current session',
      \       'write text "cd ' . a:dir . '"',
      \       'write text "clear"',
      \       'activate',
      \     'end tell',
      \   'end tell',
      \ 'end tell')
endfunction

function! s:osascript(...) abort
  let args = join(map(copy(a:000), '" -e ".shellescape(v:val)'), '')
  call  s:system('osascript'. args)
  return !v:shell_error
endfunction

function! s:system(cmd)
  let output = system(a:cmd)
  if v:shell_error && output !=# ""
    echohl Error | echom output | echohl None
    return
  endif
  return output
endfunction

function! coc#ui#set_lines(bufnr, changedtick, original, replacement, start, end, changes, cursor, col) abort
  if !bufloaded(a:bufnr)
    return
  endif
  let delta = 0
  if !empty(a:col)
    let delta = col('.') - a:col
  endif
  if getbufvar(a:bufnr, 'changedtick') > a:changedtick && bufnr('%') == a:bufnr
    " try apply current line change
    let lnum = line('.')
    " change for current line
    if a:end - a:start == 1 && a:end == lnum && len(a:replacement) == 1
      let idx = a:start - lnum + 1
      let previous = get(a:original, idx, 0)
      if type(previous) == 1
        let content = getline('.')
        if previous !=# content
          let diff = coc#string#diff(content, previous, col('.'))
          let changed = get(a:replacement, idx, 0)
          if type(changed) == 1 && strcharpart(previous, 0, diff['end']) ==# strcharpart(changed, 0, diff['end'])
            let applied = coc#string#apply(changed, diff)
            let replacement = copy(a:replacement)
            let replacement[idx] = applied
            call coc#compat#buf_set_lines(a:bufnr, a:start, a:end, replacement)
            return
          endif
        endif
      endif
    endif
  endif
  if exists('*nvim_buf_set_text') && !empty(a:changes)
    for item in reverse(copy(a:changes))
      call nvim_buf_set_text(a:bufnr, item[1], item[2], item[3], item[4], item[0])
    endfor
  else
    call coc#compat#buf_set_lines(a:bufnr, a:start, a:end, a:replacement)
  endif
  if !empty(a:cursor)
    call cursor(a:cursor[0], a:cursor[1] + delta)
  endif
endfunction

function! coc#ui#change_lines(bufnr, list) abort
  if !bufloaded(a:bufnr) | return v:null | endif
  undojoin
  if exists('*setbufline')
    for [lnum, line] in a:list
      call setbufline(a:bufnr, lnum + 1, line)
    endfor
  elseif a:bufnr == bufnr('%')
    for [lnum, line] in a:list
      call setline(lnum + 1, line)
    endfor
  else
    let bufnr = bufnr('%')
    exe 'noa buffer '.a:bufnr
    for [lnum, line] in a:list
      call setline(lnum + 1, line)
    endfor
    exe 'noa buffer '.bufnr
  endif
endfunction

function! coc#ui#open_url(url)
  if !empty(get(g:, 'coc_open_url_command', ''))
    call system(g:coc_open_url_command.' '.a:url)
    return
  endif
  if has('mac') && executable('open')
    call system('open '.a:url)
    return
  endif
  if executable('xdg-open')
    call system('xdg-open '.a:url)
    return
  endif
  call system('cmd /c start "" /b '. substitute(a:url, '&', '^&', 'g'))
  if v:shell_error
    echohl Error | echom 'Failed to open '.a:url | echohl None
    return
  endif
endfunction

function! coc#ui#rename_file(oldPath, newPath, write) abort
  let bufnr = bufnr(a:oldPath)
  if bufnr == -1
    throw 'Unable to get bufnr of '.a:oldPath
  endif
  if a:oldPath =~? a:newPath && (s:is_mac || s:is_win)
    return coc#ui#safe_rename(bufnr, a:oldPath, a:newPath, a:write)
  endif
  if bufloaded(a:newPath)
    execute 'silent bdelete! '.bufnr(a:newPath)
  endif
  let current = bufnr == bufnr('%')
  let bufname = fnamemodify(a:newPath, ":~:.")
  let filepath = fnamemodify(bufname(bufnr), '%:p')
  let winid = coc#compat#buf_win_id(bufnr)
  let curr = -1
  if winid == -1
    let curr = win_getid()
    let file = fnamemodify(bufname(bufnr), ':.')
    execute 'keepalt tab drop '.fnameescape(bufname(bufnr))
    let winid = win_getid()
  endif
  call coc#compat#execute(winid, 'keepalt file '.fnameescape(bufname), 'silent')
  call coc#compat#execute(winid, 'doautocmd BufEnter')
  if a:write
    call coc#compat#execute(winid, 'noa write!', 'silent')
    call delete(filepath, '')
  endif
  if curr != -1
    call win_gotoid(curr)
  endif
  return bufnr
endfunction

" System is case in sensitive and newPath have different case.
function! coc#ui#safe_rename(bufnr, oldPath, newPath, write) abort
  let winid = win_getid()
  let lines = getbufline(a:bufnr, 1, '$')
  execute 'keepalt tab drop '.fnameescape(fnamemodify(a:oldPath, ':.'))
  let view = winsaveview()
  execute 'keepalt bwipeout! '.a:bufnr
  if a:write
    call delete(a:oldPath, '')
  endif
  execute 'keepalt edit '.fnameescape(fnamemodify(a:newPath, ':~:.'))
  let bufnr = bufnr('%')
  call coc#compat#buf_set_lines(bufnr, 0, -1, lines)
  if a:write
    execute 'noa write'
  endif
  call winrestview(view)
  call win_gotoid(winid)
  return bufnr
endfunction

function! coc#ui#sign_unplace() abort
  if exists('*sign_unplace')
    for group in s:sign_groups
      call sign_unplace(group)
    endfor
  endif
endfunction

function! coc#ui#update_signs(bufnr, group, signs) abort
  if !s:sign_api || !bufloaded(a:bufnr)
    return
  endif
  call sign_unplace(a:group, {'buffer': a:bufnr})
  for def in a:signs
    let opts = {'lnum': def['lnum']}
    if has_key(def, 'priority')
      let opts['priority'] = def['priority']
    endif
    call sign_place(0, a:group, def['name'], a:bufnr, opts)
  endfor
endfunction

function! coc#ui#outline_preview(config) abort
  let view_id = get(w:, 'cocViewId', '')
  if view_id !=# 'OUTLINE'
    return
  endif
  let wininfo = get(getwininfo(win_getid()), 0, v:null)
  if empty(wininfo)
    return
  endif
  let border = get(a:config, 'border', v:true)
  let th = &lines - &cmdheight - 2
  let range = a:config['range']
  let height = min([range['end']['line'] - range['start']['line'] + 1, th - 4])
  let to_left = &columns - wininfo['wincol'] - wininfo['width'] < wininfo['wincol']
  let start_lnum = range['start']['line'] + 1
  let end_lnum = range['end']['line'] + 1 - start_lnum > &lines ? start_lnum + &lines : range['end']['line'] + 1
  let lines = getbufline(a:config['bufnr'], start_lnum, end_lnum)
  let content_width = max(map(copy(lines), 'strdisplaywidth(v:val)'))
  let width = min([content_width, a:config['maxWidth'], to_left ? wininfo['wincol'] - 3 : &columns - wininfo['wincol'] - wininfo['width']])
  let filetype = getbufvar(a:config['bufnr'], '&filetype')
  let cursor_row = coc#cursor#screen_pos()[0]
  let config = {
      \ 'relative': 'editor',
      \ 'row': cursor_row - 1 + height < th ? cursor_row - (border ? 1 : 0) : th - height - (border ? 1 : -1),
      \ 'col': to_left ? wininfo['wincol'] - 4 - width : wininfo['wincol'] + wininfo['width'],
      \ 'width': width,
      \ 'height': height,
      \ 'lines': lines,
      \ 'border': border ? [1,1,1,1] : v:null,
      \ 'rounded': get(a:config, 'rounded', 1) ? 1 : 0,
      \ 'winblend': a:config['winblend'],
      \ 'highlight': a:config['highlight'],
      \ 'borderhighlight': a:config['borderhighlight'],
      \ }
  let winid = coc#float#get_float_by_kind('outline-preview')
  let result = coc#float#create_float_win(winid, s:outline_preview_bufnr, config)
  if empty(result)
    return v:null
  endif
  call setwinvar(result[0], 'kind', 'outline-preview')
  let s:outline_preview_bufnr = result[1]
  if !empty(filetype)
    call coc#compat#execute(result[0], 'setfiletype '.filetype)
  endif
  return result[1]
endfunction

function! coc#ui#outline_close_preview() abort
  let winid = coc#float#get_float_by_kind('outline-preview')
  if winid
    call coc#float#close(winid)
  endif
endfunction

" Ignore error from autocmd when file opened
function! coc#ui#safe_open(cmd, file) abort
  let bufname = fnameescape(a:file)
  try
    execute a:cmd.' 'bufname
  catch /.*/
    if bufname('%') != bufname
      throw v:exception
    endif
  endtry
endfunction

" Use noa to setloclist, avoid BufWinEnter autocmd
function! coc#ui#setloclist(nr, items, action, title) abort
  if a:action ==# ' '
    let title = get(getloclist(a:nr, {'title': 1}), 'title', '')
    let action = title ==# a:title ? 'r' : ' '
    noa call setloclist(a:nr, [], action, {'title': a:title, 'items': a:items})
  else
    noa call setloclist(a:nr, [], a:action, {'title': a:title, 'items': a:items})
  endif
endfunction

function! coc#ui#get_mouse() abort
  if get(g:, 'coc_node_env', '') ==# 'test'
    return get(g:, 'mouse_position', [win_getid(), line('.'), col('.')])
  endif
  return [v:mouse_winid,v:mouse_lnum,v:mouse_col]
endfunction
