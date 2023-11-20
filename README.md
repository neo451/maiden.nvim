# maiden.nvim

WIP

## to do

- [x] access filesystem and file edit
- [x] split window remote repl
- [x] live reload on save
- [x] find a way for lua_ls to ignore norns global functions
  ```lua
   lspconfig.lua_ls.setup({
     on_attach = on_attach,
     settings = {
       Lua = {
         diagnostics = {
           globals = {
             'vim',
             'screen',
             'include',
             'util',
             '_path',
             'params',
             'clock',
             'arc',
             'audio',
             'clock',
             'controlspec',
             'crow',
             'core.crow.public',
             'core.crow.quote',
             'encoders',
             'engine',
             'gamepad',
             'grid',
             'hid',
             'keyboard',
             'metro',
             'midi',
             'norns',
             'osc',
             'params.control',
             'paramset',
             'poll',
             'screen',
             'script',
             'softcut',
           }, -- disables warning for using vim api
           disable = { 'lowercase-global' }, -- disables "lowercase-global" diagnostic
         },
         completion = {
           callSnippet = 'Replace',
         },
       },
     },
   })
  ```
- [x] read, select and install from the catalog (through maiden cli)
- [ ] make a nice lazy/mason like UI to manage scripts
- [ ] edit and load sc files?????
- [x] implement remote repl in lua for better integration and less dependency
- [ ] make a nvim-cmp source for norns methods
- [ ] auto make folder and option to unmount on vimexit
