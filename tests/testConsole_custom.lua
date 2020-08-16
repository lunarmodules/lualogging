local log_console = require"logging.console"

local logger = log_console({levels = {"DETAIL","INFO1","INFO2","WARN1","WARN2","ERROR","FATAL","OFF"}})

logger:info1("logging.console test")
logger:info2("logging.console info2 test")
logger:detail("some details...")
logger:error("error!")
logger:detail("string with %4")
logger:setLevel("INFO2") -- test log level change warning.
logger:info1("logging.console test")

print("Console Logging OK")

