local M = {}
-- more robust: add host name and command stuff
function M.run_repl()
	vim.cmd("8split | terminal")
	local command = ':call jobsend(b:terminal_job_id, "maiden\\n")'
	vim.cmd(command)
end

return M
