local ts = require("matchparen.treesitter")

describe("skip_by_region", function()
   vim.cmd.edit("tests/example.lua")
   vim.treesitter.start()
   vim.treesitter.get_parser():parse()

   local skip_fn, skip, stop

   it("should return correct function if cursor is in a skip node", function()
      -- in string
      skip_fn = assert(ts.skip_by_region(3, 49))
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
      skip_fn = assert(ts.skip_by_region(0, 2))
      skip, stop = skip_fn(1, 3)
      assert.is_false(skip)
      assert.is_false(stop)
      skip, stop = skip_fn(2, 3)
      assert.is_false(skip)
      assert.is_true(stop)
   end)

   it("should return correct skip function if cursor in not in a skip node", function()
      skip_fn = assert(ts.skip_by_region(2, 22))
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
