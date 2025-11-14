" Quick schema lookup of the current rails model
" Needs the fantastic FZF plugin to work

" NOTE: Is entirely AI generated - use at your own peril!

" ------------------------------------------------------------
" CamelCase → snake_case plural (simple)
" ------------------------------------------------------------
function! s:CamelToSnakePlural(name) abort
  let l:snake = substitute(a:name, '\(\l\)\(\u\)', '\1_\2', 'g')
  let l:snake = tolower(l:snake)
  return l:snake =~# 's$' ? l:snake : l:snake . 's'
endfunction


" ------------------------------------------------------------
" Get table name from current filename
" ------------------------------------------------------------
function! s:FileToTableName() abort
  let l:file = expand('%:t')
  if l:file !~# '\.rb$'
    return ''
  endif

  let l:base = substitute(l:file, '\.rb$', '', '')

  if l:base =~# '_'
    return l:base =~# 's$' ? l:base : l:base . 's'
  endif

  let l:snake = substitute(l:base, '\(\l\)\(\u\)', '\1_\2', 'g')
  let l:snake = tolower(l:snake)
  return l:snake =~# 's$' ? l:snake : l:snake . 's'
endfunction


" ------------------------------------------------------------
" Extract schema block from db/schema.rb → list of lines
" ------------------------------------------------------------
function! s:ExtractSchemaLines() abort
  let l:table = s:FileToTableName()
  if l:table == ''
    echo "Not a model file"
    return []
  endif

  let l:schema = findfile("db/schema.rb", ".;")
  if l:schema == ''
    echo "schema.rb not found"
    return []
  endif

  let l:lines = readfile(l:schema)
  let l:start = -1
  let l:end   = -1

  for i in range(len(l:lines))
    if l:lines[i] =~# '^  create_table "' . l:table . '"'
      let l:start = i
      continue
    endif
    if l:start != -1 && l:lines[i] =~# '^  end$'
      let l:end = i
      break
    endif
  endfor

  if l:start == -1
    echo "Table not found: " . l:table
    return []
  endif

  return l:lines[l:start : l:end]
endfunction


" ------------------------------------------------------------
" Pipe extracted schema into FZF
" ------------------------------------------------------------
function! SchemaFZF() abort
  let l:lines = s:ExtractSchemaLines()
  if empty(l:lines)
    return
  endif

  call fzf#run(fzf#wrap({
        \ 'source': l:lines,
        \ 'options': '--no-sort --prompt="schema> "'
        \ }))
endfunction


" ------------------------------------------------------------
" Mapping: Ctrl+S (must have `stty -ixon`)
" ------------------------------------------------------------
nnoremap <C-s> :call SchemaFZF()<CR>

