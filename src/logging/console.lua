-------------------------------------------------------------------------------
-- Prints logging information to console
--
-- @author Thiago Costa Ponte (thiago@ideais.com.br)
--
-- @copyright 2004-2021 Kepler Project
--
-------------------------------------------------------------------------------

local logging = require"logging"

function logging.console(params, ...)
  params = logging.getDeprecatedParams({ "logPattern" }, params, ...)
  local logPattern = params.logPattern
  local timestampPattern = params.timestampPattern

  return logging.new( function(self, level, message)
    io.stdout:write(logging.prepareLogMsg(logPattern, os.date(timestampPattern), level, message))
    return true
  end)
end

return logging.console

