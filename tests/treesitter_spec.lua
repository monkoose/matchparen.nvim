local ts = require("matchparen.treesitter")

describe("get_highlighter", function()
  it("should return nil if buffer hasn't ts hihglighter", function()
    assert.is_nil(ts.get_highlighter())
  end)

  vim.cmd("e tests/example.lua")
  it("should return highlighter table", function()
    assert.is_table(ts.get_highlighter())
    assert.truthy(ts.get_highlighter().bufnr)
  end)
  it("should return nil if ts highlight is disabled", function()
    vim.cmd("TSBufDisable highlight")
    assert.is_nil(ts.get_highlighter())
  end)
end)

describe("skip_by_region", function()
  vim.cmd("TSBufEnable highlight")
  ts.hl = ts.get_highlighter()
  local skip, stop

  it("should return just (nil, stop function) if cursor is on a skip node", function()
    skip, stop = ts.skip_by_region(2, 30)
    assert.is_nil(skip)
    assert.is_function(stop)
    assert.truthy(stop(3, 2))
    assert.falsy(stop(2, 32))
    skip, stop = ts.skip_by_region(0, 2)
    assert.falsy(stop(1, 3))
  end)

  it("should return correct skip and stop functions", function()
    skip, stop = ts.skip_by_region(2, 15)
    assert.is_function(skip)
    assert.is_function(stop)
    assert.truthy(skip(2, 30))
    assert.truthy(skip(3, 2))
    assert.falsy(skip(2, 20))
  end)

end)

-- vim:sw=2:et
