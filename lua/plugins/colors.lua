-- COLORSCHEME
--------------------------------------------------
-- The one plugin with no lazy trigger: it has to be in place
-- before the first buffer is drawn, or the editor flashes the
-- default theme. `priority` puts it ahead of the other
-- startup plugins (lze defaults to 50).
--
-- Nothing is configured here. lua/core/theme.lua feeds it the
-- palette, and init.lua requires that last, once this has
-- loaded.

return {
	{
		"base16-nvim",

		enabled = true,
		auto_enable = true,
		lazy = false,

		priority = 1000,
	},
}
