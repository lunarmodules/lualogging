-------------------------------------------------------------------------------
-- Prints logging information to console
--
-- @author Thiago Costa Ponte (thiago@ideais.com.br)
--
-- @copyright 2004-2021 Kepler Project
--
-------------------------------------------------------------------------------

local io = require"io"
local logging = require"logging"
local prepareLogMsg = logging.prepareLogMsg

local destinations = setmetatable({
    stdout = "stdout",
    stderr = "stderr",
  },
  {
    __index = function(self, key)
      if not key then
        return "stdout" -- default value
      end
      error("destination parameter must be either 'stderr' or 'stdout', got: "..tostring(key), 3)
    end
  })

function logging.console(params, ...)
  params = logging.getDeprecatedParams({ "logPattern" }, params, ...)
  local logPattern = params.logPattern
  local timestampPattern = params.timestampPattern
  local destination = destinations[params.destination]

  return logging.new( function(self, level, message)
    io[destination]:write(prepareLogMsg(logPattern, timestampPattern, level, message))
    return true
  end)
end

return logging.console

