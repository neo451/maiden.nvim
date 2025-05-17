local websocket_client = require("ws.websocket_client")
local maiden = require("maiden")
local host = maiden.defaults.addr
local M = {}
local ws = websocket_client("ws://" .. host .. ":5555/", "bus.sp.nanomsg.org")
-- local float = require("float")

function M.repl()
	local buf = float.Create({ width = 45, height = 10, buflisted = true, title = "floattyyy" })
	local write_to_buf = function(msg)
		vim.api.nvim_buf_set_lines(buf, 0, -1, false, { msg })
	end
	local _msg = ""

	local function send_input()
		local input = vim.fn.input(">> ", "")

		if input == "exit" or input == ":q" then
			ws.close()
			return
		end
		input = input .. "\n"
		ws.send(input)
		vim.schedule(send_input)
	end
	vim.schedule(send_input)
	ws.on_message(function(msg)
		vim.schedule(function()
			_msg = msg:to_string()
			write_to_buf(_msg)
		end)
	end)
end

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
