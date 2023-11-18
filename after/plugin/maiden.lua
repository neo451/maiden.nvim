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
    args = { '--host', host, 'send', "norns.script.load(norns.state.script)" },
		on_exit = function(j, return_val)
			print("Return value:", return_val)
			print("Output:", table.concat(j:result(), "\n"))
		end,
		on_stderr = function(_, data)
			print("Error:", table.concat(data, "\n"))
		end,
	}):start() -- Use sync to wait for the job to finish
end

vim.api.nvim_create_autocmd(
  {"BufWritePost"},
  {
    pattern = defaults.dir.."/*.lua",
    callback = load_script,}
)

-- TODO: OR A FUNCTION TO MANUALY UPDATE
-- vim.api.nvim_create_user_command("MaidenUpdate",
--
-- )
--
-- TODO: FUNCTION TO END PALYING
-- vim.api.nvim_create_user_command("MaidenStop",
--
-- )

-- TODO: FUNCTION TO UPDATE FORM A GIT REPO
