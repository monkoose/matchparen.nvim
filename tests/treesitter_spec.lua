local ts = require('matchparen.treesitter')

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
  ts.highlighter = ts.get_highlighter()
  local skip

  it('should return correct function if cursor is in a skip node', function()
    -- in string
    skip = ts.skip_by_region(2, 30)
    assert.is_function(skip)
    assert.same({ stop = true }, skip(2, 2))
    assert.same({ stop = true }, skip(3, 2))
    assert.same({ skip = false }, skip(2, 32))
    -- in comment
    skip = ts.skip_by_region(0, 2)
    assert.same({ skip = false }, skip(1, 3))
    assert.same({ stop = true }, skip(2, 3))
  end)

  it('should return correct skip function if cursor in not in a skip node', function()
    skip = ts.skip_by_region(2, 15)
    assert.is_function(skip)
    assert.same({ skip = true }, skip(2, 30))
    assert.same({ skip = true }, skip(3, 2))
    assert.same({ skip = false }, skip(2, 20))
  end)

end)

-- vim:sw=2:et
