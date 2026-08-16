-- READING BOOLEANS FROM THE NIX CONFIG
--------------------------------------------------
-- `nixInfo(default, ...)` cannot return `false`: when the value
-- it finds is falsy it hands back the default instead, so a
-- flag turned off in Nix reads as if it were on. Booleans have
-- to go through the parent table, which does carry the real
-- value, and be indexed in Lua.

local M = {}

-- Boolean at `path`, or `default` when it is not set at all
function M.bool(default, ...)
	local path = { ... }
	local key = table.remove(path)
	local parent = nixInfo(nil, unpack(path))
	if type(parent) ~= "table" or parent[key] == nil then
		return default
	end
	return parent[key] == true
end

return M
