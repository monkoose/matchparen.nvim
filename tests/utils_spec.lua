local utils = require("matchparen.utils")
local stub = require("luassert.stub")

describe("dec", function()
  it("should decrement a number", function()
    assert.equal(utils.dec(5), 4)
  end)
end)

describe("inc", function()
  it("should increment a number", function()
    assert.equal(6, utils.inc(5))
  end)
end)

describe("str_contains", function()
  local text = "Hello, world!"

  it("should return true if pattern is in a text", function()
    assert.is_true(utils.str_contains(text, "ell"))
  end)

  it("should return false if pattern is not in a text", function()
    assert.is_false(utils.str_contains(text, "oll"))
  end)
end)

describe("find_forward", function()
  local text = "Some boring boring text here"
  it("should return index and pattern", function()
    assert.same({6, "bor"}, {utils.find_forward(text, "(bor)")})
  end)
  it("should return nil", function()
    assert.falsy(utils.find_forward(text, "br"))
    assert.falsy(utils.find_forward(text, "bor", 20))
  end)
end)

describe("find_backward", function()
  local reversed_text = string.reverse("Some boring boring text here")
  it("should return index and pattern", function()
    assert.same({#reversed_text - 13, "rob"},
        {utils.find_backward(reversed_text, "(rob)")})
  end)
  it("should return nil", function()
    assert.falsy(utils.find_backward(reversed_text, "rb"))
    assert.falsy(utils.find_backward(reversed_text, "rob", 3))
  end)
end)

describe("is_in_insert_mode", function()
  local cur_mode = stub(vim.api, "nvim_get_mode")

  it("should return true in insert or replace modes", function()
    cur_mode.returns({ mode = "i"})
    assert.is_true(utils.is_in_insert_mode())
    cur_mode.returns({ mode = "R"})
    assert.is_true(utils.is_in_insert_mode())
  end)

  it("sould return false in not insert or replace modes", function()
    cur_mode.returns({ mode = "v"})
    assert.is_false(utils.is_in_insert_mode())
    cur_mode.returns({ mode = "c"})
    assert.is_false(utils.is_in_insert_mode())
  end)

  cur_mode:revert()
end)

describe("Functional", function()
  vim.cmd("e tests/example.lua")
  local test_string = "-- test get_line"

  describe("get_line", function()
    vim.api.nvim_win_set_cursor(0, { 2, 4 })
    it("should return correct text of the line number", function()
      -- get_line is 0-based
      assert.equal(test_string, utils.get_line(1))
    end)
  end)

  describe("get_reversed_line", function()
    vim.api.nvim_win_set_cursor(0, { 2, 4 })
    it("should return correct reversed text of the line number", function()
      assert.equal(string.reverse(test_string), utils.get_reversed_line(1))
    end)
  end)

  describe("get_current_pos", function()
    it("should return 0-based line, column", function()
      assert.same({1, 4}, {utils.get_current_pos()})
    end)
  end)

  vim.cmd("bw")
end)

-- vim:sw=2:et
