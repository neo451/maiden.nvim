local M = {}
M.defaults = {
	dir = "/home/n451/remote-norns",
	addr = "192.168.43.179",
}
local websocket_client = require("ws.websocket_client")
local Job = require("plenary.job")
local stackmap = require("stackmap")
local host = M.defaults.addr
local ws = websocket_client("ws://" .. host .. ":5555/", "bus.sp.nanomsg.org")
local catalog = require("catalog")

-- TODO: USE NATIVE REPL TO STOP etc
-- TODO: TRY NETMAN OR COMMIT TO SSHFS?
M.setup = function(opts)
	M.defaults = vim.tbl_extend("force", M.defaults, opts or {})
end

function M.sync()
	local addr = vim.fn.input("Enter norns address: ")
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
	-- M.send_oneoff("script.run()")
	-- M.send_oneoff("script.load(norns.state.script)")
end

M.reload_script()

-- TODO: MAKE this more generic to handle project and catalog
-- TODO: LOOK HIGHTLIGHT STUFF TO DIFFERENCIATE PROJECT AND CATALOG

local get_script = function()
	local line = vim.api.nvim_get_current_line()
	local match = line:match("%S+%s(%S+)")
	print(match)
	local res = {}
	for _, v in ipairs(catalog) do
		if match == v["project_name"] then
			res[1], res[2] = v["project_url"], v["documentation_url"]
		end
	end
	return res[1], res[2], match
end

local keymaps = {
	["<leader>i"] = ":lua require'maiden'.install_from_line()<cr>",
	["<leader>u"] = ":lua require'maiden'.uninstall_form_line()<cr>",
	["<leader>d"] = ":lua require'maiden'.open_documentation_url()<cr>",
	["<leader>p"] = ":lua require'maiden'.open_project_url()<cr>",
}
-- TODO: COMPARE WITH PROJECT LIST AND ADD AVILABLE TAGS AND INSTALLED
function M.show_scripts()
	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_option(buf, "filetype", "markdown")
	local width = 120
	local height = 20
	vim.api.nvim_open_win(buf, true, {
		relative = "editor",
		width = width,
		height = height,
		row = math.floor(vim.o.lines / 2 - height / 2),
		col = math.floor(vim.o.columns / 2 - width / 2),
		focusable = true,
		style = "minimal",
		border = "double",
	})
	for _, v in ipairs(catalog) do
		local line = "# " .. v.project_name
		local desc = v.description
		if v.tags ~= nil then
			desc = "* " .. desc .. " | " .. table.concat(v["tags"], ", ")
		end
		vim.api.nvim_buf_set_lines(buf, -1, -1, false, { line, desc })
	end
	stackmap.push("maiden", "n", keymaps)
end

function M.install(script)
	Job:new({
		command = "ssh",
		args = {
			"we@192.168.43.179",
			"maiden/maiden project install " .. script,
		},
		on_exit = function(_, exit_code)
			if exit_code ~= 0 then
				print("Error executing the command. Error code:", exit_code)
			else
				print("installed")
			end
		end,
	}):start()
end

local function uninstall(script)
	Job:new({
		command = "ssh",
		args = {
			"we@192.168.43.179",
			"maiden/maiden project remove " .. script,
		},
		on_exit = function(_, exit_code)
			if exit_code ~= 0 then
				print("Error executing the command. Error code:", exit_code)
			else
				print("uninstalled")
			end
		end,
	}):start()
end

M.install_from_line = function()
	local _, _, line = get_script()
	M.install(line)
end

M.uninstall = function()
	local script = vim.fn.input("Enter script name: ")
	uninstall(script)
end

M.uninstall_form_line = function()
	local _, _, line = get_script()
	uninstall(line)
end

-- macos: just open
M.open_documentation_url = function()
	local _, url = get_script()
	Job:new({
		command = "xdg-open",
		args = { url },
	}):start()
end

M.open_project_url = function()
	local url = get_script()
	Job:new({
		command = "xdg-open",
		args = { url },
	}):start()
end

return M
