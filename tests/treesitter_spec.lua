local ts = require("matchparen.treesitter")

describe("get_highlighter", function()
   it("should return nil if buffer hasn't treesitter hihglighter", function()
      assert.is_nil(ts.get_highlighter())
   end)

   vim.cmd.edit("tests/example.lua")
   vim.treesitter.start()

   it("should return highlighter table", function()
      assert.is_table(ts.get_highlighter())
      assert.truthy(ts.get_highlighter().bufnr)
   end)
   it("should return nil if treesitter is disabled", function()
      vim.treesitter.stop()
      assert.is_nil(ts.get_highlighter())
   end)

   vim.cmd("bw!")
end)

describe("skip_by_region", function()
   vim.cmd.edit("tests/example.lua")
   vim.treesitter.start()
   vim.treesitter.get_parser():parse()

   ts.highlighter = ts.get_highlighter()
   local skip_fn, skip, stop

   it("should return correct function if cursor is in a skip node", function()
      -- in string
      skip_fn = ts.skip_by_region(3, 49)
      assert.is_function(skip_fn)

      skip, stop = skip_fn(3, 36)
      assert.is_false(skip)
      assert.is_true(stop)

      skip, stop = skip_fn(3, 30)
      assert.is_false(skip)
      assert.is_true(stop)

      skip, stop = skip_fn(3, 55)
      assert.is_false(skip)
      assert.is_false(stop)

      -- in comment
      skip_fn = ts.skip_by_region(0, 2)
      skip, stop = skip_fn(1, 3)
      assert.is_false(skip)
      assert.is_false(stop)
      skip, stop = skip_fn(2, 3)
      assert.is_false(skip)
      assert.is_true(stop)
   end)

   it("should return correct skip function if cursor in not in a skip node", function()
      skip_fn = ts.skip_by_region(2, 22)
      assert.is_function(skip_fn)

      skip, stop = skip_fn(2, 30)
      assert.is_true(skip)
      assert.is_false(stop)

      skip, stop = skip_fn(3, 14)
      assert.is_false(skip)
      assert.is_false(stop)

      skip, stop = skip_fn(2, 22)
      assert.is_false(skip)
      assert.is_false(stop)
   end)

   vim.cmd("bw!")
end)
