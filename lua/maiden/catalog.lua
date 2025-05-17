---@class norns.project
---@field project_url string
---@field project_name string
---@field documentation_url string
---@field author string
---@field discussion_url string
---@field description string
---@field tags string[]

---@class norns.catalog
---@field prjects norns.project[]
local M = {}
local util = require("maiden.util")

local url = "https://raw.githubusercontent.com/monome/norns-community/refs/heads/main/community.json"

local data_dir = vim.fs.joinpath(vim.fn.stdpath("data"), "maiden")

if not vim.uv.fs_stat(data_dir) then
	vim.fn.mkdir(data_dir, "-p")
end

local function fetch()
	local cmds = { "curl", url, "-o", "community.json" }
	vim.system(
		cmds,
		{ cwd = data_dir },
		vim.schedule_wrap(function(obj)
			if obj.code == 0 then
				vim.notify("Successfully updated community catalog", vim.log.levels.INFO)
			else
				vim.notify("Failed to updat community catalog", vim.log.levels.ERROR)
			end
		end)
	)
end

local function load()
	local catalog_path = vim.fs.joinpath(data_dir, "community.json")
	local str = util.read_file(catalog_path)
	assert(str)
	return vim.json.decode(str).entries
end

function M.update()
	fetch()
	M.prjects = load()
end

M.prjects = load()

return M
