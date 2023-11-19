local websocket_client = require("ws.websocket_client")
local maiden = require("maiden")
local host = maiden.defaults.addr

-- TODO: Make a floating window to display the returned message, read the API 
-- TODO: MAKE A PULL REQUEST OR FORK A WORKING VERSION WITH THE SUBPROTOCAL SUPPORT
local function create_client()
	local ws = websocket_client("ws://" .. host .. ":5555/")

	local function send_input()
		local input = vim.fn.input(">> ", "")

		if input == "exit" then
			ws.close()
			return
		end
    input = input .. "\n"
		ws.send(input)
		vim.schedule(send_input)
	end

	ws.on_open(function()
		print("Connected to server.")
		vim.schedule(send_input) 	end)

	ws.on_close(function()
		print("Connection closed.")
	end)

	ws.on_message(function(msg)
		msg = msg:to_string()
  --   vim.schedule(function ()
  --   vim.api.nvim_buf_set_text(61, 0, 0, 0, -1, {msg})
  -- end)
		print("Server response: " .. msg)
	end)

	return ws
end

local ws_client = create_client()
ws_client.connect()
