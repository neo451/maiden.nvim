local M = {}

local maiden = require("maiden")
local host = maiden.defaults.addr

function M.run_repl()
	vim.cmd("7split | terminal")
	local argument = "maiden-remote-repl" .. " --host " .. host
	local command = string.format(':call jobsend(b:terminal_job_id, "%s\\n")', argument)
	vim.cmd(command)
end

return M
