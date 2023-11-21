local M = {}
local stackmap = require("stackmap")
local websocket_client = require("ws.websocket_client")

M.defaults = {
	dir = "/home/n451/snorns",
	addr = "192.168.43.179",
}
-- HACK: !!!!
local function add_command(name, fn, desc)
  vim.api.nvim_buf_create_user_command(0, name, fn, { desc = desc })
end




-- TODO: USE NATIVE REPL TO STOP etc
-- TODO: TRY NETMAN OR COMMIT TO SSHFS?
-- TODO: LIVE RELOAD MAYBE SHOULD BE BIND TO KEYMAP RATHER THAN AUTO
M.setup = function(opts)
	M.defaults = vim.tbl_extend("force", M.defaults, opts or {})
end

local Job = require("plenary.job")
function M.sync(addr)
	if addr == "" then
		addr = M.defaults.addr
	end
	Job:new({
		command = "sshfs",
		args = {
			"-o",
			"default_permissions",
			"we@" .. addr .. ":/home/we/dust/code",
			M.defaults.dir,
		},
		on_exit = function()
			print("Synced!")
		end,
		on_stderr = function()
			print("Error: failed to connect to norns")
		end,
	}):start()
end

function M.unsync()
	Job:new({
		command = "fusermount",
		args = { "-zu", M.defaults.dir },
		on_exit = function()
			print("Unsynced!")
		end,
		on_stderr = function()
			print("Error: failed to unsync")
		end,
	}):start()
end

local host = M.defaults.addr
local ws = websocket_client("ws://" .. host .. ":5555/", "bus.sp.nanomsg.org")

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

function M.load_script()
	local line = vim.api.nvim_get_current_line()
	M.send_oneoff(line)
end

-- TODO: make a user command
function M.reload_script()
	M.send_oneoff("norns.script.load(norns.state.script)")
end

-- TODO: FUNCTION TO END PALYING
function M.stop_script()
	M.send_oneoff("clock.transport.stop()")
end
-- TODO: NOT RIGHT
function M.run_script(script)
  local name = string.format("norns.script.load('%s')", script)
	M.send_oneoff(name)
end

local catalog = {}

local function clean_string(input_string)
	local cleaned_elements = {}
	for elem1, elem2, elem3 in string.gmatch(input_string, "(.-)\t\t+(.-)\t\t+(.+)") do
		cleaned_elements[1] = elem1:match("^%s*(.-)%s*$")
		cleaned_elements[2] = elem2:match("^%s*(.-)%s*$")
		cleaned_elements[3] = elem3:match("^%s*(.-)%s*$")
	end
	return cleaned_elements
end

local function clean_catalog()
	local res = {}
	for _, v in ipairs(catalog) do
		table.insert(res, clean_string(v))
	end
	return res
end

local function list_catalog()
	Job:new({
		command = "ssh",
		args = {
			"we@192.168.43.179",
			"maiden/maiden catalog list",
		},
		on_stdout = function(_, data)
			table.insert(catalog, data)
		end,
		on_exit = function(_, exit_code)
			if exit_code == 0 then
				print("Command executed successfully")
			else
				print("Error executing the command. Error code:", exit_code)
			end
		end,
	}):sync()
	return clean_catalog()
end

function M.get_script()
  local line = vim.api.nvim_get_current_line()
  local path = line:match("(.+)%s")
  print(path)
end

-- HACK: same for project manager UNINSTALL(U)
-- HACK: MAKE KEYMAPS TO INSTALL(I), VIEW NORNS COMMITY(N)

local keymaps = {
  ["<C-i>"] = ":lua require'maiden'.get_script()<cr>",
}

-- TODO: MAKE this more generic to handle project and catalog
local function show_scripts()
	local buf = vim.api.nvim_create_buf(false, true)
	local width = 80
	local height = 10
	local win_id = vim.api.nvim_open_win(buf, true, {
		relative = "editor",
		width = width,
		height = height,
		row = math.floor(vim.o.lines / 2 - height / 2),
		col = math.floor(vim.o.columns / 2 - width / 2),
		focusable = true,
		style = "minimal",
		border = "double",
	})
	for _, v in ipairs(list_catalog()) do
		local line = ""
		if v[3] ~= nil and v[3] ~= "[]" then
			line = v[1] .. " " .. v[3]
		else
			line = v[1]
		end
		vim.api.nvim_buf_set_lines(buf, -1, -1, false, { line })
	end
  vim.api.nvim_buf_set_option(buf, 'modifiable', false)
  stackmap.push("maiden", "n", keymaps)
end

local function install(script)
	Job:new({
		command = "ssh",
		args = {
			"we@192.168.43.179",
			"maiden/maiden project install " .. script,
		},
		on_stdout = function(_, data)
			table.insert(catalog, data)
		end,
		on_exit = function(_, exit_code)
			if exit_code ~= 0 then
				print("Error executing the command. Error code:", exit_code)
			end
		end,
	}):start()
end

-- TODO: UNINSTALL
local function uninstall(script) end

return M
