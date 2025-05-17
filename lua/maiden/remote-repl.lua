local websocket_client = require("ws.websocket_client")
local maiden = require("maiden")
local host = maiden.defaults.addr
local M = {}
-- local ws = websocket_client("ws://" .. host .. ":5555/", "bus.sp.nanomsg.org")
-- local float = require("float")

local config = require("maiden.config")
local state = require("maiden.state")

local function ensure_client()
	local client = state.client
	if client then
		if client.host == config.host then
			return
		end
		-- close("Close because host changed.")
	end
	local port = 5555
	state.client = require("maiden.websocket").new(config.host, port, "/", { "bus.sp.nanomsg.org" })
	client = state.client
	client.on_message = function(msg)
		vim.notify(msg, vim.log.levels.INFO)
	end
	client.on_close = function(reason)
		client = nil
		if reason then
			vim.notify(reason, vim.log.levels.WARN)
		end
	end
	client.on_open = function()
		vim.notify("Connected.", vim.log.levels.INFO)
	end
end

-- function M.repl()
-- 	local _msg = ""
--
-- 	local function send_input()
-- 		local input = vim.fn.input(">> ", "")
--
-- 		if input == "exit" or input == ":q" then
-- 			ws.close()
-- 			return
-- 		end
-- 		input = input .. "\n"
-- 		ws.send(input)
-- 		vim.schedule(send_input)
-- 	end
-- 	vim.schedule(send_input)
-- 	ws.on_message(function(msg)
-- 		vim.schedule(function()
-- 			_msg = msg:to_string()
-- 			write_to_buf(_msg)
-- 		end)
-- 	end)
-- end
--
-- M.repl()

function M.send_oneoff(command)
	local _msg = ""
	ws.on_open(function()
		ws.send(command .. "\n")
		print("connected")
	end)
	ws.on_message(function(msg)
		_msg = msg:to_string()
		print(_msg)
	end)
	ws.connect()
end

M.send_oneoff("print('hello')")
-- TODO: MAKE A PULL REQUEST OR FORK A WORKING VERSION WITH THE SUBPROTOCAL SUPPORT

return M
