-- PATHS
--------------------------------------------------

local M = {}

-- Directory holding this Lua config.
--
-- Under the wrapper it is the Nix store path injected as
-- `settings.config_directory`, not `stdpath("config")` --
-- that one still points at ~/.config/nvim, which a wrapper
-- user usually does not even have.
function M.config()
	local dir = nixInfo(nil, "settings", "config_directory")
	if dir and vim.fn.isdirectory(dir) == 1 then
		return dir
	end
	return vim.fn.stdpath("config")
end

return M
