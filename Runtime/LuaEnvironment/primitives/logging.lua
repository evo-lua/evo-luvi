local logging = {}

-- Severities are based on the standard syslog template, with additions for testing and events
function logging.event(message, ...)
	print("[EVENT]", message, ...)
end
function logging.test(message, ...)
	print("[TEST]", message, ...)
end
function logging.debug(message, ...)
	print("[DEBUG]", message, ...)
end
function logging.info(message, ...)
	print("[INFO]", message, ...)
end
function logging.notice(message, ...)
	print("[NOTICE]", message, ...)
end
function logging.warning(message, ...)
	print("[WARNING]", message, ...)
end
function logging.error(message, showTraceback)
	error(message .. (showTraceback and debug.traceback("", 2) or ""), 0)
end
function logging.critical(message, ...)
	print("[CRITICAL]", message, ...)
end
function logging.alert(message, ...)
	print("[ALERT]", message, ...)
end
function logging.emergency(message, ...)
	print("[EMERGENCY]", message, ...)
end

_G.EVENT = logging.event
_G.TEST = logging.test
_G.DEBUG = logging.debug
_G.INFO = logging.info
_G.NOTICE = logging.notice
_G.WARNING = logging.warning
_G.ERROR = logging.error
_G.CRITICAL = logging.critical
_G.ALERT = logging.alert
_G.EMERGENCY = logging.emergency

return logging
