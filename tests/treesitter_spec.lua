local ts = require('matchparen.treesitter')
local opts = require('matchparen.options').opts

describe('get_highlighter', function()
  it("should return nil if buffer hasn't ts hihglighter", function()
    assert.is_nil(ts.get_highlighter())
  end)

  vim.cmd('e tests/example.lua')
  it('should return highlighter table', function()
    assert.is_table(ts.get_highlighter())
    assert.truthy(ts.get_highlighter().bufnr)
  end)
  it('should return nil if ts highlight is disabled', function()
    vim.cmd('TSBufDisable highlight')
    assert.is_nil(ts.get_highlighter())
  end)
end)

describe('skip_by_region', function()
  vim.cmd('TSBufEnable highlight')
  opts.cache.hl = ts.get_highlighter()
  local skip

  it('should return correct function if cursor is in a skip node', function()
    -- in string
    skip = ts.skip_by_region(2, 30)
    assert.is_function(skip)
    assert.equals(0, skip(2))
    assert.equals(-1, skip(3, 2))
    assert.equals(0, skip(2, 32))
    -- in comment
    skip = ts.skip_by_region(0, 2)
    assert.equals(0, skip(1, 3))
    assert.equals(-1, skip(2, 3))
  end)

  it('should return correct skip function if cursor in not in a skip node', function()
    skip = ts.skip_by_region(2, 15)
    assert.is_function(skip)
    assert.equals(1, skip(2, 30))
    assert.equals(1, skip(3, 2))
    assert.equals(0, skip(2, 20))
  end)

end)

-- vim:sw=2:et
