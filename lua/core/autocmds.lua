-- AUTOCOMMANDS AND FILETYPES
--------------------------------------------------

-- INDENTATION
--------------------------------------------------
-- Two spaces for the languages in the daily profile;
-- everything else keeps the four-space default set in
-- core/options.lua.
vim.api.nvim_create_autocmd("FileType", {
	pattern = {
		"nix",
		"lua",
		"json",
		"jsonc",
		"yaml",
		"markdown",
		"sh",
		"bash",
		"html",
		"css",
		"javascript",
		"typescript",
	},
	callback = function(args)
		vim.opt_local.tabstop = 2
		vim.opt_local.shiftwidth = 2
		vim.opt_local.softtabstop = 2
		vim.opt_local.expandtab = true
		-- Nix comments start with `#`: smartindent would push
		-- them back to column zero
		if args.match == "nix" then
			vim.opt_local.smartindent = false
			vim.opt_local.indentkeys:remove("0#")
			vim.opt_local.cinkeys:remove("0#")
		end
	end,
})

-- MARKDOWN
--------------------------------------------------
-- Text wrapping, `:MdWrap` and the filetype-local keymaps
-- live in their own module.
require("core.mdwrap")

-- Spell checking, off until toggled
require("core.spell")
