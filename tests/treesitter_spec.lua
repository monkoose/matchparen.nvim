local ts = require("matchparen.treesitter")
local STATUS = require("matchparen.enum").STATUS

describe("skip_by_region", function()
   vim.cmd.edit("tests/example.lua")
   vim.treesitter.start()
   vim.treesitter.get_parser():parse()

   local skip_fn, res

   it("should return correct function if cursor is in a skip node", function()
      -- in string
      skip_fn = assert(ts.skip_by_region(3, 49))
      assert.is_function(skip_fn)

      res = skip_fn(3, 36)
      assert.equal(STATUS.abort, res)

      res = skip_fn(3, 30)
      assert.equal(STATUS.abort, res)

      res = skip_fn(3, 55)
      assert.equal(STATUS.ok, res)

      -- in comment
      skip_fn = assert(ts.skip_by_region(0, 2))
      res = skip_fn(1, 3)
      assert.equal(STATUS.ok, res)
      res = skip_fn(2, 3)
      assert.equal(STATUS.abort, res)
   end)

   it("should return correct skip function if cursor in not in a skip node", function()
      skip_fn = assert(ts.skip_by_region(2, 22))
      assert.is_function(skip_fn)

      res = skip_fn(2, 30)
      assert.equal(STATUS.skip, res)

      res = skip_fn(3, 14)
      assert.equal(STATUS.ok, res)

      res = skip_fn(2, 22)
      assert.equal(STATUS.ok, res)
   end)

   vim.cmd("bw!")
end)
