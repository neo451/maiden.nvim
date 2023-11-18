local m = require 'maiden'
vim.api.nvim_create_user_command("MaidenStart", function()
	local addr = vim.fn.input("Enter norns address: ")
	m.sync(addr)
end, {})

vim.api.nvim_create_user_command("MaidenEnd", function()
	m.unsync()
end, {})


vim.api.nvim_create_autocmd({ "BufWritePost" }, {
	pattern = m.defaults.dir .. "/*.lua",
	callback = m.load_script,
})

vim.api.nvim_create_user_command("MaidenInstall", function()
	local package = vim.fn.input("Enter package to install: ")
	m.install(package)
end, {})
