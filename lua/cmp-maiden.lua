local source = {}
local catalog = require("catalog")
local items = {}

function source.get_trigger_characters()
  return {}
end

function source.get_keyword_pattern()
  return [[\(:MaidenInstall\)\@<=\S\+\s*]]
end

for _, v in pairs(catalog) do
	if v["tags"] ~= nil then
		table.insert(items, {
			label = v["project_name"],
			kind = "norns",
			documentation = v["description"] .. " | " .. table.concat(v["tags"], ", "),
		})
	else
		table.insert(items, {
			label = v["project_name"],
			kind = "norns",
			documentation = v["description"],
		})
	end
end

source.new = function()
	local self = setmetatable({}, { __index = source })
	return self
end

function source:is_available()
	return true
end

function source:get_debug_name()
	return "norns"
end


function source:complete(_, callback)
	callback(items)
end
return source
