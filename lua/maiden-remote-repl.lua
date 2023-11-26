local websocket_client = require("ws.websocket_client")
local maiden = require("maiden")
local host = maiden.defaults.addr
local M = {}
local ws = websocket_client("ws://" .. host .. ":5555/", "bus.sp.nanomsg.org")
local win = require('float')

function M.start_repl()
	ws.on_message(function(msg)
		local _msg = msg:to_string()
		print(_msg:match("[^%c]+"))
	end)

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

	ws.on_open(function()
		vim.schedule(send_input)
	end)
	ws.connect()
end

-- TODO: Make a floating window to display the returned message, read the API
win.Create({height = 10, width = 30, title = "Maiden REPL"})
-- TODO: MAKE A PULL REQUEST OR FORK A WORKING VERSION WITH THE SUBPROTOCAL SUPPORT
return M
