local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local catalog = require("catalog")
local entry_display = require("telescope.pickers.entry_display")
local make_entry = require("telescope.make_entry")

local title_table = {}

for i, v in ipairs(catalog) do
	title_table[i] = v.project_name
end

-- TODO: understand this to make handle the table
function gen_from_norns_catalog(opts)
	local displayer = entry_display.create({
		separator = " ",
		hl_chars = { ["["] = "TelescopeBorder", ["]"] = "TelescopeBorder" },
		items = {
			{ width = 20 },
			{ remaining = true },
		},
	})

	local make_display = function(entry)
		return displayer({
			"[" .. entry.content.project_name .. "]",
			-- entry.content.tags,
			entry.content.description,
		})
	end

	return function(entry)
		return make_entry.set_default_entry_mt({
			ordinal = entry.project_name .. entry.description,
			content = entry,
			display = make_display,
		}, opts)
	end
end
-- gen_from_norns_catalog()(catalog[1])
-- our picker function: colors
local tele_norns = function(opts)
	opts = opts or {}
	pickers
		.new(opts, {
			prompt_title = "norns",
			finder = finders.new_table({
				results = catalog,
				entry_maker = gen_from_norns_catalog(opts), --TODO:
			}),
			sorter = conf.generic_sorter(opts),
			attach_mappings = function(prompt_bufnr, map)
				actions.select_default:replace(function()
					actions.close(prompt_bufnr)
					local selection = action_state.get_selected_entry()
					print(vim.inspect(selection))
					vim.api.nvim_put({ selection[1] }, "", false, true)
				end)
				return true
			end,
		})
		:find()
end

-- to execute the function
-- tele_norns(require("telescope.themes").get_ivy({}))
tele_norns()
