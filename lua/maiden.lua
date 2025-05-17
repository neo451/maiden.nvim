local M = {}
local cmds = {}

local catalog = require("maiden.catalog")
local config = require("maiden.config")
local Norns = require("maiden.norns")
local util = require("maiden.util")

-- TODO: USE NATIVE REPL TO STOP etc
-- TODO: TRY NETMAN OR COMMIT TO SSHFS?
function M.setup(opts)
	vim.api.nvim_create_user_command("Maiden", function()
		vim.ui.select(vim.tbl_keys(cmds), {}, function(choice)
			if not choice then
				return
			end
			cmds[choice]()
		end)
	end, {})
end

local mount_dir = vim.fn.tempname()

local function mount(addr)
	if not vim.uv.fs_stat(mount_dir) then
		vim.fn.mkdir(mount_dir, "-p")
	end

	local cmds = {
		"sshfs",
		"-o",
		"default_permissions",
		"we@" .. addr .. ":/home/we/dust/code",
		mount_dir,
	}

	vim.system(cmds, {}, function(obj)
		local ok = obj.code == 0
		if ok then
			util.notify("Synced to norns", vim.log.levels.INFO)
		else
			util.notify("Failed to sync to norns " .. obj.stderr, vim.log.levels.ERROR)
		end
	end)
end

function cmds.mount()
	vim.ui.input({
		default = config.addr,
		prompt = "Enter norns address: ",
	}, function(input)
		if not input or input == "" then
			util.notify("Aborted", 3)
			return
		end
		mount(input)
	end)
end

---Check if in norns's fs
---@return boolean
---@return string?
local function in_fs()
	local buf = vim.api.nvim_get_current_buf()
	local file = vim.api.nvim_buf_get_name(buf)

	if vim.startswith(file, vim.fs.normalize(mount_dir)) then
		return true, file
	end
	return false
end

function cmds.broswer()
	local is_fs, fp = in_fs()

	if is_fs then
		local rel_path = fp:gsub(vim.pesc(mount_dir), "")
		local prefix = "/maiden/#edit/dust/code" .. rel_path -- TODO： other dir like audio and data
		vim.ui.open("http://" .. config.addr .. prefix)
	else
		vim.ui.open("http://" .. config.addr)
	end
end

function cmds.unmount()
	local cmds = {
		"fusermount",
		"-zu",
		mount_dir,
	}

	vim.system(cmds, {}, function(obj)
		local ok = obj.code == 0
		if ok then
			util.notify("Unsynced from norns", vim.log.levels.INFO)
		else
			util.notify("Failed to unsync from norns " .. obj.stderr, vim.log.levels.ERROR)
		end
	end)
end

vim.api.nvim_create_autocmd("VimLeavePre", {
	pattern = "*",
	callback = function()
		cmds.unmount()
	end,
})

-- TODO:
local function load_script()
	local line = vim.api.nvim_get_current_line()
	cmds.send_oneoff(line)
end

-- TODO: make a user command
local function reload_script()
	-- M.send_oneoff("script.run()")
	-- M.send_oneoff("script.load(norns.state.script)")
end

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
			util.notify("Error executing the command. Error code: " .. exit_code, vim.log.levels.ERROR)
		else
			util.notify(script .. " installed", vim.log.levels.ERROR)
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
			util.notify("Error executing the command. Error code: " .. exit_code, vim.log.levels.ERROR)
		else
			util.notify(script .. " uninstalled", vim.log.levels.ERROR)
		end
	end)
end

cmds.install = function()
	vim.ui.input({ prompt = "script to install: " }, function(input)
		if not input then
			util.notify("Aborted", 3)
			return
		end
		install(input)
	end)
end

cmds.uninstall = function()
	vim.ui.input({ prompt = "script to uninstall: " }, function(input)
		if not input then
			util.notify("Aborted", 3)
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
function cmds.menu()
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

function cmds.open()
	vim.cmd.edit(mount_dir)
end

function cmds.quickfix()
	Norns:qf()
end

return M
