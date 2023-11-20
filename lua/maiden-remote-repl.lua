local websocket_client = require("ws.websocket_client")
local maiden = require("maiden")
local host = maiden.defaults.addr
local M = {}
local ws = websocket_client("ws://" .. host .. ":5555/")
-- local ws = websocket_client("ws://websocket-echo.com/")

function M.start_repl()
	local bufnr = vim.api.nvim_create_buf(false, true)
	local width = 80
	local height = 10
	local win_id = vim.api.nvim_open_win(bufnr, true, {
		relative = "editor",
		width = width,
		height = height,
		row = math.floor(vim.o.lines / 2 - height / 2),
		col = math.floor(vim.o.columns / 2 - width / 2),
		focusable = true,
		style = "minimal",
	})

	ws.on_message(function(msg)
		_msg = msg:to_string()
		print(_msg:match("[^%c]+"))
		vim.schedule(function()
			vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { _msg:match("[^%c]+") })
		end)
	end)

	local function send_input()
		local input = vim.fn.input(">> ", "")

		if input == "exit" or input == ":q" then
			ws.close()
			vim.api.nvim_win_close(win_id, true)
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
-- one off channel??
function M.send_oneoff(command)
	local _msg = ""
	ws.on_open(function()
		ws.send(command .. "\n")
	end)
	ws.on_message(function(msg)
		_msg = msg:to_string()
		print(_msg)
	end)
	ws.connect()
end

M.send_oneoff("sequence = false")

-- TODO: Make a floating window to display the returned message, read the API
-- TODO: MAKE A PULL REQUEST OR FORK A WORKING VERSION WITH THE SUBPROTOCAL SUPPORT
return M
