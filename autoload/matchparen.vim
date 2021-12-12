function! matchparen#skip() abort
  return luaeval("require'matchparen.block'.skip()")
endfunction
