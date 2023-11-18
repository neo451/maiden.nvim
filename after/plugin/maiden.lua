local defaults = {
	dir = "/home/n451/snorns",
	addr = "192.168.43.179",
}

local Job = require("plenary.job")
local function sync(dir, addr)
	Job:new({
		command = "sshfs",
		args = {
			"-o",
			"default_permissions",
			"we@" .. addr .. ":/home/we/dust/code",
			dir,
		},
		on_exit = function()
			print("Synced!")
		end,
		on_stderr = function()
			print("Error: failed to connect to norns")
		end,
	}):start()
end

local function unsync(dir)
	Job:new({
		command = "fusermount",
		args = { "-zu", dir },
		on_exit = function()
			print("Unsynced!")
		end,
		on_stderr = function()
			print("Error: failed to unsync")
		end,
	}):start()
end

vim.api.nvim_create_user_command("MaidenStart", function()
	local addr = vim.fn.input("Enter norns address: ")
	if addr == "" then
		addr = defaults.addr
	end
	sync(defaults.dir, addr)
end, {})

vim.api.nvim_create_user_command("MaidenEnd", function()
	unsync(defaults.dir)
end, {})

local function load_script()
	local host = defaults.addr
	Job:new({
		command = "maiden-remote-repl",
		args = { "--host", host, "send", "norns.script.load(norns.state.script)" },
		on_exit = function(j, return_val)
			print("Return value:", return_val)
			print("Output:", table.concat(j:result(), "\n"))
		end,
		on_stderr = function(_, data)
			print("Error:", table.concat(data, "\n"))
		end,
	}):start() -- Use sync to wait for the job to finish
end

vim.api.nvim_create_autocmd({ "BufWritePost" }, {
	pattern = defaults.dir .. "/*.lua",
	callback = load_script,
})

-- TODO: OR A FUNCTION TO MANUALY UPDATE
-- vim.api.nvim_create_user_command("MaidenUpdate",
--
-- )
--
-- TODO: FUNCTION TO END PALYING
-- vim.api.nvim_create_user_command("MaidenStop",
--
-- )

-- TODO: list the catalog

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
	for i, v in ipairs(catalog) do
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
		on_stdout = function(j, data)
			table.insert(catalog, data)
		end,
		on_exit = function(j, exit_code)
			if exit_code == 0 then
				print("Command executed successfully")
			else
				print("Error executing the command. Error code:", exit_code)
			end
		end,
	}):sync()
	return clean_catalog()
end

-- TODO: FUNCTION TO install a script
local function install(script)
	Job:new({
		command = "ssh",
		args = {
			"we@192.168.43.179",
			"maiden/maiden project install " .. script
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

vim.api.nvim_create_user_command("MaidenInstall", function()
	local package = vim.fn.input("Enter package to install: ")
	install(package)
end, {})
