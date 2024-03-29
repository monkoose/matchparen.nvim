local syntax = require('matchparen.syntax')

describe('skip_by_region', function()
  vim.cmd('e tests/example.lua')
  if vim.fn.exists(':TSBufDisable') ~= 0 then
    vim.cmd('TSBufDisable highlight')
  end

  it('should return correct function when cursor is on string or comment', function()
    assert.same({ skip = false }, syntax.skip_by_region(2, 30)(2, 30))
    assert.same({ skip = false }, syntax.skip_by_region(3, 14)(3, 14))
    assert.same({ skip = true }, syntax.skip_by_region(2, 30)(6, 4))
    assert.same({ skip = true }, syntax.skip_by_region(3, 14)(6, 4))
  end)
  it('should return correct function when cursor is not on string or comment', function()
    assert.same({ skip = false }, syntax.skip_by_region(2, 10)(2, 10))
    assert.same({ skip = false }, syntax.skip_by_region(6, 4)(6, 4))
    assert.same({ skip = true }, syntax.skip_by_region(2, 10)(3, 14))
    assert.same({ skip = true }, syntax.skip_by_region(2, 10)(2, 30))
  end)
  it('should return nil if syntax option is empty', function()
    vim.cmd('set syntax=')
    assert.is_nil(syntax.skip_by_region(2, 30))
    vim.cmd('set syntax=lua')
  end)
  it('should return nil if syntax is off', function()
    vim.cmd('syntax off')
    assert.is_nil(syntax.skip_by_region(2, 30))
    vim.cmd('syntax on')
  end)

  vim.cmd('bw!')
end)

-- vim:sw=2:et
