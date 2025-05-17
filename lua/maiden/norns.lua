local M = {}

local config = require("maiden.config")
local ws = require("maiden.websocket")

M.__index = M

local qflist = {}

local function handle_new_msg(text)
	for line in vim.gsplit(text, "\n", { trimempty = true }) do
		local filename, lnum, etext = line:match("^%s*/home/we/dust/([^:]+):(%d+):%s+(.*)")
		if filename then
			table.insert(qflist, { filename = filename, lnum = lnum, text = etext })
		end
	end
end

function M.new()
	local client = ws.new(config.addr, 5555, "/", { "bus.sp.nanomsg.org" })
	client.on_message = function(msg)
		print(msg)
		handle_new_msg(msg)
	end

	client.on_open = function()
		print("Connected")
	end

	client.on_close = print

	return setmetatable({
		client = client,
	}, M)
end

function M:send(msg)
	self.client:send(msg .. "\n")
end

function M.qf()
	local l = qflist
	qflist = {}
	for _, qf in ipairs(l) do
		qf.lnum = tonumber(qf.lnum)
		-- qf.filename = d .. qf.filename
	end
	vim.fn.setqflist(l)
end

local norns = M.new()
--
-- vim.defer_fn(function()
-- 	norns:send([[print('hi!')]])
-- end, 2000)

return M
