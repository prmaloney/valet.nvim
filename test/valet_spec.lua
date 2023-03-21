local valet = require('valet')
local Path = require('plenary.path')
local mock = require('luassert.mock')
local stub = require('luassert.stub')

local function assert_table_equals(tbl1, tbl2)
  if #tbl1 ~= #tbl2 then
    assert(false, "" .. #tbl1 .. " != " .. #tbl2)
  end
  for i = 1, #tbl1 do
    if tbl1[i] ~= tbl2[i] then
      assert.equals(tbl1[i], tbl2[i])
    end
  end
end

describe('valet functionality', function()

  stub(Path, 'write')

  end)
  it('Sets default config if file does not exist', function()
    local path_read = mock(Path.read, true)
    path_read.returns('')

    valet.setup()
    local expected = { projects = {} }

    assert.equals(vim.inspect(valet.get_valet_config()), vim.inspect(expected))
  end)

  it('Sets default config to the cached value if it exists', function()
    local path_read = mock(Path.read, true)
    local cache_config = { projects = { '/some/project' } }

    path_read.returns(vim.inspect(cache_config))

    valet.setup()

    assert.equals(vim.inspect(valet.get_valet_config()), vim.inspect(cache_config))
  end)
end)
