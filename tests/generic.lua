local logging = require "logging"
local call_count
local last_msg
local msgs

function logging.test(params)
  local logPattern = params.logPattern
  local timestampPattern = params.timestampPattern
  return logging.new( function(self, level, message)
    last_msg = logging.prepareLogMsg(logPattern, os.date(timestampPattern), level, message)
    msgs = msgs or {}
    table.insert(msgs, last_msg)
    --print("----->",last_msg)
    call_count = call_count + 1
    return true
  end, params)
end

local function reset()
  call_count = 0
  last_msg = nil
  msgs = nil
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

  params = logging.getDeprecatedParams(list, 1, nil, 3)
  assert(params.param1 == 1)
  assert(params.next_one == nil)
  assert(params.hello_world == 3)
end


tests.log_levels = function()
  local logger = logging.test { logPattern = "%message", timestampPattern = nil }
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


tests.custom_log_levels = function()
  -- existing properties are not allowed as level names
  local custom_levels = { "append", "debug" }
  local logger, err = logging.test {
    logPattern = "%message",
    timestampPattern = nil,
    levels = custom_levels,
  }
  assert(not logger)
  assert(err:find("'APPEND' is not a proper level name"), "got: " .. tostring(err))


  local custom_levels = { "hello", "world" }
  local logger = logging.test {
    logPattern = "%message",
    timestampPattern = nil,
    levels = custom_levels,
  }
  -- generates the levels
  assert(logger.HELLO == "HELLO", "got: " .. tostring(logger.HELLO))
  assert(logger.WORLD == "WORLD", "got: " .. tostring(logger.WORLD))
  -- debug no longer exists
  local success, err = pcall(function()
    logger:setLevel(logger.DEBUG)
  end)
  assert(not success)
  assert(err:find("undefined level `nil'"), "got: " .. tostring(err))
  -- 'hello' exists
  local success, err = pcall(function()
    logger:setLevel(logger.HELLO)
  end)
  assert(success)
  assert(err == nil, "got: " .. tostring(err))
  logger:hello("my message")
end


tests.table_serialization = function()
  local logger = logging.test { logPattern = "%message", timestampPattern = nil }

  logger:debug({1,2,3,4,5,6,7,8,9,10})
  assert(last_msg == "{1, 10, 2, 3, 4, 5, 6, 7, 8, 9}", "got: " .. tostring(last_msg))

  logger:debug({abc = "cde", "hello", "world", xyz = true, 1, 2, 3})
  assert(last_msg == '{"hello", "world", 1, 2, 3, abc = "cde", xyz = true}', "got: " .. tostring(last_msg))
end


tests.print_function = function()
  local logger = logging.test { logPattern = "%level %message" }
  local print = logger:getPrint(logger.DEBUG)
  print("hey", "there", "dude")
  assert(msgs[1] == "DEBUG hey there dude")
  print()
  assert(msgs[2] == "DEBUG ")
  print("hello\nthere")
  assert(msgs[3] == "DEBUG hello")
  assert(msgs[4] == "DEBUG there")
  print({}, true, nil, 0)
  assert(msgs[5]:find("table"))
  assert(msgs[5]:find(" true nil 0$"))
end


tests.formatting = function()
  local count = 0
  local logger = logging.test { logPattern = "%level %message" }

  logger:debug("%s-%s", 'abc', '007')
  assert(last_msg == 'DEBUG abc-007')

  logger:debug("%s", nil)
  assert(last_msg:find("bad argument #2 to 'format' %(no value%)"))
  assert(last_msg:find("in main chunk"))
  assert(last_msg:find("in function 'func'"))
  local _, levels = last_msg:gsub("(|)", function() count = count + 1 end)
  assert(levels == 3, "got : " .. levels)
end


for name, func in pairs(tests) do
  reset()
  print("generic test: " .. name)
  func()
end

print("[v] all generic tests succesful")
