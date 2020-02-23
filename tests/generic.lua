local logging = require "logging"
local call_count
local last_msg

function logging.test(logPattern)
  return logging.new( function(self, level, message)
    last_msg = logging.prepareLogMsg(logPattern, os.date(), level, message)
    call_count = call_count + 1
    return true
  end)
end

local function reset()
  call_count = 0
  last_msg = nil
end

local tests = {}




tests.deprecated_parameter_handling = function()
  local list = { "param1", "next_one", "hello_world" }
  local params = logging.getDeprecatedParams(list, {
    param1 = 1,
    next_one = nil,
    hello_world = 3,
  })
  assert(params.param1 == 1)
  assert(params.next_one == nil)
  assert(params.hello_world == 3)

  local params = logging.getDeprecatedParams(list, 1, nil, 3)
  assert(params.param1 == 1)
  assert(params.next_one == nil)
  assert(params.hello_world == 3)
end




for name, func in pairs(tests) do
  reset()
  print("generic test: " .. name)
  func()
end

print("[v] all generic tests succesful")
