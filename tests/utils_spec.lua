local utils = require('matchparen.utils')
local stub = require('luassert.stub')

describe('str_contains', function()
  local text = 'Hello, world!'

  it('should return true if pattern is in a text', function()
    assert.is_true(utils.str_contains(text, 'ell'))
  end)

  it('should return false if pattern is not in a text', function()
    assert.is_false(utils.str_contains(text, 'oll'))
  end)
end)

describe('str_contains_any', function()
  local text = 'Hello, world!'

  it('should return true if any element of the table is in a text', function()
    assert.is_true(utils.str_contains_any(text, { 'oll', 'ell' }))
  end)

  it('should return false if any element of the table is not in a text', function()
    assert.is_false(utils.str_contains_any(text, { 'oll', 'lolo' }))
  end)
end)

describe('find_forward', function()
  local text = 'Some boring boring text here'
  it('should return index and pattern', function()
    assert.same({6, 'bor'}, {utils.find_forward(text, '(bor)')})
  end)
  it('should return nil', function()
    assert.is_nil(utils.find_forward(text, 'br'))
    assert.is_nil(utils.find_forward(text, 'bor', 20))
  end)
end)

describe('find_backward', function()
  local reversed_text = string.reverse('Some boring boring text here')
  it('should return index and pattern', function()
    assert.same({#reversed_text - 13, 'rob'},
        {utils.find_backward(reversed_text, '(rob)')})
  end)
  it('should return nil', function()
    assert.is_nil(utils.find_backward(reversed_text, 'rb'))
    assert.is_nil(utils.find_backward(reversed_text, 'rob', 3))
  end)
end)

describe('is_in_insert_mode', function()
  local cur_mode = stub(vim.api, 'nvim_get_mode')

  it('should return true in insert or replace modes', function()
    cur_mode.returns({ mode = 'i'})
    assert.is_true(utils.is_in_insert_mode())
    cur_mode.returns({ mode = 'R'})
    assert.is_true(utils.is_in_insert_mode())
  end)

  it('sould return false in not insert or replace modes', function()
    cur_mode.returns({ mode = 'v'})
    assert.is_false(utils.is_in_insert_mode())
    cur_mode.returns({ mode = 'c'})
    assert.is_false(utils.is_in_insert_mode())
  end)

  cur_mode:revert()
end)

describe('Functional', function()
  vim.cmd('e tests/example.lua')
  local test_strings = {'-- Testing file', '-- test get_line'}

  describe('get_lines', function()
    it('should return correct array of strings.', function()
      assert.same(test_strings, utils.get_lines(0, 2))
      assert.same({ test_strings[2] }, utils.get_lines(1, 1))
    end)
  end)

  describe('get_cursor_pos', function()
    vim.api.nvim_win_set_cursor(0, { 2, 4 })
    it('should return 0-based line, column', function()
      assert.same({1, 4}, {utils.get_cursor_pos()})
    end)
  end)

  describe('is_inside_fold', function()
    it('should return false outside of closed fold', function()
      assert.is_false(utils.is_inside_fold(utils.get_cursor_pos()))
    end)
    vim.api.nvim_feedkeys('zfj', 'nx', false)
    it('should return true when cursor is in closed fold', function()
      assert.is_true(utils.is_inside_fold(utils.get_cursor_pos()))
    end)
  end)

  vim.cmd('bw')
end)

-- vim:sw=2:et
