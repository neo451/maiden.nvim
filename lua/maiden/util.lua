local M = {}

---@param fp string
---@param str string
---@param mode "w" | "a"
---@return boolean
M.save_file = function(fp, str, mode)
	mode = mode or "w"
	local f = io.open(fp, mode)
	if f then
		f:write(str)
		f:close()
		return true
	else
		return false
	end
end

---@param path string
---@return string?
M.read_file = function(path)
	local ret
	local f = io.open(path, "r")
	assert(f, "could not open " .. path)
	ret = f:read("*a")
	f:close()
	return ret
end

return M
