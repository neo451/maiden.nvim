local M = {}

M.defaults = {
	dir = "/home/n451/remote-norns",
	addr = "192.168.43.179",
}

local websocket_client = require("ws.websocket_client")
local ws = websocket_client("ws://" .. M.defaults.addr .. ":5555/", "bus.sp.nanomsg.org") -- TODO: user config
local catalog = require("maiden.catalog")

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

	local cmds = {
		"sshfs",
		"-o",
		"default_permissions",
		"we@" .. addr .. ":/home/we/dust/code",
		M.defaults.dir,
	}

	vim.system(cmds, {}, function(obj)
		local ok = obj.code == 0
		if ok then
			vim.notify("Synced to norns", vim.log.levels.INFO)
		else
			vim.notify("Failed to sync to norns", vim.log.levels.ERROR)
		end
	end)
end

function M.unsync()
	local cmds = {
		"fusermount",
		"-zu",
		M.defaults.dir,
	}

	vim.system(cmds, {}, function(obj)
		local ok = obj.code == 0
		if ok then
			vim.notify("Unsynced from norns", vim.log.levels.INFO)
		else
			vim.notify("Failed to unsync from norns", vim.log.levels.ERROR)
		end
	end)
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

-- TODO: ts get heading above

local get_project = function()
	local line = vim.api.nvim_get_current_line()
	local match = line:match("%S+%s(%S+)")
	return vim.iter(catalog.prjects):find(function(project)
		return project.project_name == match
	end)
end

---@param script string
local function install(script)
	local cmds = {
		"ssh",
		"we@192.168.43.179",
		"maiden/maiden project install " .. script,
	}

	vim.system(cmds, {}, function(obj)
		local exit_code = obj.code
		if exit_code ~= 0 then
			vim.notify("Error executing the command. Error code: " .. exit_code, vim.log.levels.ERROR)
		else
			vim.notify(script .. " installed", vim.log.levels.ERROR)
		end
	end)
end

---@param script string
local function uninstall(script)
	local cmds = {
		"ssh",
		"we@192.168.43.179",
		"maiden/maiden project remove " .. script,
	}

	vim.system(cmds, {}, function(obj)
		local exit_code = obj.code
		if exit_code ~= 0 then
			vim.notify("Error executing the command. Error code: " .. exit_code, vim.log.levels.ERROR)
		else
			vim.notify(script .. " uninstalled", vim.log.levels.ERROR)
		end
	end)
end

M.install = function()
	vim.ui.input({ prompt = "script to install: " }, function(input)
		if not input then
			vim.notify("Aborted", 3)
			return
		end
		install(input)
	end)
end

M.uninstall = function()
	vim.ui.input({ prompt = "script to uninstall: " }, function(input)
		if not input then
			vim.notify("Aborted", 3)
			return
		end
		uninstall(input)
	end)
end

local keymaps = {
	["i"] = function()
		local name = get_project().project_name
		install(name)
	end,
	["u"] = function()
		local name = get_project().project_name
		uninstall(name)
	end,
	["d"] = function()
		local url = get_project().documentation_url
		vim.ui.open(url)
	end,
	["p"] = function()
		local url = get_project().project_url
		vim.ui.open(url)
	end,
	q = function()
		vim.cmd.close()
	end,
}

-- TODO: COMPARE WITH PROJECT LIST AND ADD AVILABLE TAGS AND INSTALLED
function M.show_scripts()
	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_set_option_value("filetype", "markdown", { buf = buf })
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
	for _, v in ipairs(catalog.prjects) do
		local line = "# " .. v.project_name
		local desc = v.description
		if v.tags ~= nil then
			desc = "* " .. desc .. " | " .. table.concat(v["tags"], ", ")
		end
		vim.api.nvim_buf_set_lines(buf, -1, -1, false, { line, "", desc, "" })
	end

	for lhs, rhs in pairs(keymaps) do
		vim.keymap.set("n", lhs, rhs, { buffer = buf })
	end
end

return M
