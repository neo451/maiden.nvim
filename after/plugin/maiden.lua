local m = require("maiden")

local function add_command(name, fn)
	vim.api.nvim_create_user_command(name, function()
		fn()
	end, {})
end

add_command("MaidenStart", m.sync)
add_command("MaidenEnd", m.unsync)
add_command("MaidenScripts", m.show_scripts)

vim.api.nvim_create_user_command("MaidenInstall", function(opts)
	m.install(opts.args)
end, { nargs = "?" })

vim.api.nvim_create_autocmd({ "BufWritePost" }, {
	pattern = m.defaults.dir .. "/*.lua",
	callback = m.load_script,
})

-- require('cmp').register_source('norns', require("cmp-maiden").new())
