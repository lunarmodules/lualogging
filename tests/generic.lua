local logging = require "logging"
local call_count
local last_msg

function logging.test(params)
  local logPattern = params.logPattern
  local timestampPattern = params.timestampPattern
  return logging.new( function(self, level, message)
    last_msg = logging.prepareLogMsg(logPattern, os.date(timestampPattern), level, message)
    --print("----->",last_msg)
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


tests.log_levels = function()
  local logger = logging. test { logPattern = "%message", timestampPattern = nil }
  logger:setLevel(logger.DEBUG)
  -- debug gets logged
  logger:debug("message 1")
  assert(last_msg == "message 1", "got: " .. tostring(last_msg))
  assert(call_count == 1, "Got: " ..  tostring(call_count))
  -- fatal also gets logged at 'debug' setting
  logger:fatal("message 2")
  assert(last_msg == "message 2", "got: " .. tostring(last_msg))
  assert(call_count == 2, "Got: " ..  tostring(call_count))

  logger:setLevel(logger.FATAL)
  -- debug gets logged
  logger:debug("message 3")  -- should not change the last message
  assert(last_msg == "message 2", "got: " .. tostring(last_msg))
  assert(call_count == 2, "Got: " ..  tostring(call_count))
  -- fatal also gets logged at 'debug' setting
  logger:fatal("message 4") -- should be logged as 3rd message
  assert(last_msg == "message 4", "got: " .. tostring(last_msg))
  assert(call_count == 3, "Got: " ..  tostring(call_count))

  logger:setLevel(logger.OFF)
  -- debug gets logged
  logger:debug("message 5")  -- should not change the last message
  assert(last_msg == "message 4", "got: " .. tostring(last_msg))
  assert(call_count == 3, "Got: " ..  tostring(call_count))
  -- fatal also gets logged at 'debug' setting
  logger:fatal("message 6")  -- should not change the last message
  assert(last_msg == "message 4", "got: " .. tostring(last_msg))
  assert(call_count == 3, "Got: " ..  tostring(call_count))
  -- should never log "OFF", even if its set
  logger:fatal("message 7")  -- should not change the last message
  assert(last_msg == "message 4", "got: " .. tostring(last_msg))
  assert(call_count == 3, "Got: " ..  tostring(call_count))
end



for name, func in pairs(tests) do
  reset()
  print("generic test: " .. name)
  func()
end

print("[v] all generic tests succesful")
