local m = require("maiden")

local cmds = {
	"mount",
	"unmount",
	"menu",
	"open",
	"quickfix",
}

vim.api.nvim_create_user_command("Maiden", function()
	vim.ui.select(cmds, {}, function(choice)
		if not choice then
			return
		end
		m[choice]()
	end)
end, {})

-- add_command("MaidenStart", m.sync)
-- add_command("MaidenEnd", m.unsync)
-- add_command("MaidenScripts", m.menu)

-- vim.api.nvim_create_user_command("MaidenInstall", function(opts)
-- 	m.install(opts.args)
-- end, { nargs = "?" })

-- vim.api.nvim_create_autocmd({ "BufWritePost" }, {
-- 	-- pattern = m.defaults.dir .. "/*.lua",
-- 	-- callback = m.load_script,
-- })

-- require('cmp').register_source('norns', require("cmp-maiden").new())
