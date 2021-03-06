function! lsp#ui#vim#utils#locations_to_loc_list(result) abort
    if !has_key(a:result['response'], 'result')
        return []
    endif

    let l:list = []

    let l:locations = type(a:result['response']['result']) == type({}) ? [a:result['response']['result']] : a:result['response']['result']

    if !empty(l:locations) " some servers also return null so check to make sure it isn't empty
        for l:location in l:locations
            if s:is_file_uri(l:location['uri'])
                let l:path = lsp#utils#uri_to_path(l:location['uri'])
                let l:line = l:location['range']['start']['line'] + 1
                let l:col = l:location['range']['start']['character'] + 1
                call add(l:list, {
                    \ 'filename': l:path,
                    \ 'lnum': l:line,
                    \ 'col': l:col,
                    \ 'text': s:get_loc_text(l:path, l:line),
                    \ })
            endif
        endfor
    endif

    return l:list
endfunction

let s:symbol_kinds = {
    \ '1': 'file',
    \ '2': 'module',
    \ '3': 'namespace',
    \ '4': 'package',
    \ '5': 'class',
    \ '6': 'method',
    \ '7': 'property',
    \ '8': 'field',
    \ '9': 'constructor',
    \ '10': 'enum',
    \ '11': 'interface',
    \ '12': 'function',
    \ '13': 'variable',
    \ '14': 'constant',
    \ '15': 'string',
    \ '16': 'number',
    \ '17': 'boolean',
    \ '18': 'array',
    \ }

function! lsp#ui#vim#utils#symbols_to_loc_list(result) abort
    if !has_key(a:result['response'], 'result')
        return []
    endif

    let l:list = []

    let l:locations = type(a:result['response']['result']) == type({}) ? [a:result['response']['result']] : a:result['response']['result']

    if !empty(l:locations) " some servers also return null so check to make sure it isn't empty
        for l:symbol in a:result['response']['result']
            let l:location = l:symbol['location']
            if s:is_file_uri(l:location['uri'])
                let l:path = lsp#utils#uri_to_path(l:location['uri'])
                let l:bufnr = bufnr(l:path)
                let l:line = l:location['range']['start']['line'] + 1
                let l:col = l:location['range']['start']['character'] + 1
                call add(l:list, {
                    \ 'filename': l:path,
                    \ 'lnum': l:line,
                    \ 'col': l:col,
                    \ 'text': s:get_symbol_text_from_kind(l:symbol['kind']) . ' : ' . l:symbol['name'],
                    \ })
            endif
        endfor
    endif

    return l:list
endfunction

function! s:is_file_uri(uri) abort
    return stridx(a:uri, 'file:///') == 0
endfunction

if has("unix")
    function! s:get_loc_text(path, lineno) abort
        " Use sed to avoid loading the entire file into memory.
        return system("sed -n " . a:lineno . "p < " . shellescape(a:path))
    endfunction
else
    function! s:get_loc_text(path, lineno) abort
        return readfile(a:path, a:lineno)[a:lineno - 1]
    endfunction
endif

function! s:get_symbol_text_from_kind(kind)
    return has_key(s:symbol_kinds, a:kind) ? s:symbol_kinds[a:kind] : 'unknown symbol ' . a:kind
endfunction
