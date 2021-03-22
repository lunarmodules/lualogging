-------------------------------------------------------------------------------
-- includes a new tostring function that handles tables recursively
--
-- @author Danilo Tuler (tuler@ideais.com.br)
-- @author Andre Carregal (info@keplerproject.org)
-- @author Thiago Costa Ponte (thiago@ideais.com.br)
--
-- @copyright 2004-2021 Kepler Project
-------------------------------------------------------------------------------

local type, table, string, _tostring, tonumber = type, table, string, tostring, tonumber
local select = select
local error = error
local format = string.format
local pairs = pairs
local ipairs = ipairs

local logging = {
  -- Meta information
  _COPYRIGHT = "Copyright (C) 2004-2021 Kepler Project",
  _DESCRIPTION = "A simple API to use logging features in Lua",
  _VERSION = "LuaLogging 1.5.1",
}

local LEVELS = { "DEBUG", "INFO", "WARN", "ERROR", "FATAL", "OFF" }
local MAX_LEVELS = #LEVELS
for i, level in ipairs(LEVELS) do
  LEVELS[level] = i
  logging[level] = level
end


local function rewrite_stacktrace()
  -- prettify stack-trace, remove lualogging entries and reformat to 1 line
  local result = ''
  local trace = debug.traceback()
  for entry in trace:gmatch("%s*(.-)\n") do
    if entry:match("%:%d+%:") and not entry:find('logging.lua') then
      result = result .. ' | ' .. entry
    end
  end
  return result
end

-- private log function, with support for formating a complex log message.
local function LOG_MSG(self, level, fmt, ...)
  local f_type = type(fmt)
  if f_type == 'string' then
    if select('#', ...) > 0 then
      local status, msg = pcall(format, fmt, ...)
      if status then
        return self:append(level, msg)
      else
        return self:append(level, "Error formatting log message: " ..
                                  msg .. rewrite_stacktrace())
      end
    else
      -- only a single string, no formating needed.
      return self:append(level, fmt)
    end
  elseif f_type == 'function' then
    -- fmt should be a callable function which returns the message to log
    return self:append(level, fmt(...))
  end
  -- fmt is not a string and not a function, just call tostring() on it.
  return self:append(level, logging.tostring(fmt))
end

-- do nothing function for disabled levels.
local function disable_level() end

-- a generic print function that prints to the log
local function print_to_log(logger, level, ...)
  local args = { n = select("#", ...), ... }
  for i = 1, args.n do args[i] = _tostring(args[i]) end
  args = table.concat(args, " ") .. "\n"
  for line in args:gmatch("(.-)\n") do
    logger:log(level, line)
  end
end

-- improved assertion function.
local function assert(exp, ...)
  -- if exp is true, we are finished so don't do any processing of the parameters
  if exp then return exp, ... end
  -- assertion failed, raise error
  error(format(...), 2)
end

-------------------------------------------------------------------------------
-- Creates a new logger object
-- @param append Function used by the logger to append a message with a
-- log-level to the log stream.
-- @return Table representing the new logger object.
-- @return String if there was any error setting the custom levels if provided
-------------------------------------------------------------------------------
function logging.new(append)
  if type(append) ~= "function" then
    return nil, "Appender must be a function."
  end

  local LEVEL_FUNCS = {}

  local logger = {}
  logger.append = append

  logger.setLevel = function (self, level)
    local order = LEVELS[level]
    assert(order, "undefined level '%s'", _tostring(level))
    local old_level = self.level
    self.level = level
    self.level_order = order
    -- enable/disable levels
    for i=1, MAX_LEVELS do
      local name = LEVELS[i]:lower()
      if i >= order and i ~= MAX_LEVELS then
        self[name] = LEVEL_FUNCS[i]
      else
        self[name] = disable_level
      end
    end
    if old_level and old_level ~= level then
      self:log(LEVELS[1], "Logger: changing loglevel from %s to %s", old_level, level)
    end
  end

  -- generic log function.
  logger.log = function (self, level, ...)
    local order = LEVELS[level]
    assert(order, "undefined level `%s'", _tostring(level))
    if order < self.level_order then
      return
    end
    return LOG_MSG(self, level, ...)
  end

  -- a print function generator
  logger.getPrint = function (self, level)
    local order = LEVELS[level]
    assert(order, "undefined level `%s'", _tostring(level))
    return function(...)
      if order >= self.level_order then
        print_to_log(self, level, ...)
      end
    end
  end

  -- create the proxy functions for each log level.
  for i=1, MAX_LEVELS do
    local level = LEVELS[i]
    if logger[level:lower()] then
      return nil, "'" .. level .."' is not a proper level name since there is already a property '" .. level:lower() .. "'"
    end
    LEVEL_FUNCS[i] = function(self, ...)
      -- no level checking needed here, this function will only be called if it's level is active.
      return LOG_MSG(self, level, ...)
    end
  end

  -- insert log level constants
  for i=1, MAX_LEVELS do
    logger[LEVELS[i]] = LEVELS[i]
  end

  -- initialize log level.
  logger:setLevel(LEVELS[1])
  return logger
end


-------------------------------------------------------------------------------
-- Prepares the log message
-------------------------------------------------------------------------------
function logging.prepareLogMsg(pattern, dt, level, message)
  local logMsg = pattern or "%date %level %message\n"
  message = string.gsub(message, "%%", "%%%%")
  logMsg = string.gsub(logMsg, "%%date", dt)
  logMsg = string.gsub(logMsg, "%%level", level)
  logMsg = string.gsub(logMsg, "%%message", message)
  return logMsg
end


-------------------------------------------------------------------------------
-- Converts a Lua value to a string
--
-- Converts Table fields in alphabetical order
-------------------------------------------------------------------------------
local function tostring(value)
  local str = ''

  if (type(value) ~= 'table') then
    if (type(value) == 'string') then
      str = string.format("%q", value)
    else
      str = _tostring(value)
    end
  else
    local auxTable = {}
    for key in pairs(value) do
      if (tonumber(key) ~= key) then
        table.insert(auxTable, key)
      else
        table.insert(auxTable, tostring(key))
      end
    end
    table.sort(auxTable)

    str = str..'{'
    local separator = ""
    local entry
    for _, fieldName in ipairs(auxTable) do
      if ((tonumber(fieldName)) and (tonumber(fieldName) > 0)) then
        entry = tostring(value[tonumber(fieldName)])
      else
        entry = fieldName.." = "..tostring(value[fieldName])
      end
      str = str..separator..entry
      separator = ", "
    end
    str = str..'}'
  end
  return str
end
logging.tostring = tostring

-------------------------------------------------------------------------------
-- Backward compatible parameter handling
-------------------------------------------------------------------------------
function logging.getDeprecatedParams(lst, ...)
  local args = { n = select("#", ...), ...}
  if type(args[1]) == "table" then
    -- this is the new format of a single params-table
    return args[1]
  end

  local params = {}
  for i, param_name in ipairs(lst) do
    params[param_name] = args[i]
  end
  return params
end


if _VERSION < 'Lua 5.2' then
  -- still create 'logging' global for Lua versions < 5.2
  _G.logging = logging
end

return logging
