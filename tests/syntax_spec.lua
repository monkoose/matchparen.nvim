local syntax = require('matchparen.syntax')

describe('skip_by_region', function()
  vim.cmd('e tests/example.lua')
  if vim.fn.exists(':TSBufDisable') ~= 0 then
    vim.cmd('TSBufDisable highlight')
  end

  it('should return function that returns 0 when cursor is on string or comment', function()
    assert.equals(0, syntax.skip_by_region(2, 30)(2, 30))
    assert.equals(0, syntax.skip_by_region(3, 14)(3, 14))
  end)
  it('should return function that returns 0 when cursor is not on string or comment', function()
    assert.equals(0, syntax.skip_by_region(2, 10)(2, 10))
    assert.equals(0, syntax.skip_by_region(6, 4)(6, 4))
  end)

  it('should return function that returns 1 when cursor is on string or comment', function()
    assert.equals(1, syntax.skip_by_region(2, 30)(6, 4))
    assert.equals(1, syntax.skip_by_region(3, 14)(6, 4))
  end)
  it('should return function that returns 1 when cursor is not on string or comment', function()
    assert.equals(1, syntax.skip_by_region(2, 10)(3, 14))
    assert.equals(1, syntax.skip_by_region(2, 10)(2, 30))
  end)

  it('should return nil if syntax option is empty', function()
    vim.cmd('set syntax=')
    assert.falsy(syntax.skip_by_region(2, 30))
    vim.cmd('set syntax=lua')
  end)
  it('should return nil if syntax is off', function()
    vim.cmd('syntax off')
    assert.falsy(syntax.skip_by_region(2, 30))
    vim.cmd('syntax on')
  end)

  vim.cmd('bw!')
end)

-- vim:sw=2:et
