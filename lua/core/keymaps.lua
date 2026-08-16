-- GLOBAL KEYMAPS
--------------------------------------------------
-- A plugin's own maps live in its spec; filetype-local ones
-- live in core/autocmds.lua.

-- Line navigation: H to the start, L to the end.
-- Works in operator pending too (dL, yH).
vim.keymap.set({ "n", "x", "o" }, "H", "^", { desc = "Go to start of line" })
vim.keymap.set({ "n", "x", "o" }, "L", "$", { desc = "Go to end of line" })

-- MARKDOWN EMPHASIS
--------------------------------------------------
-- Wrap the visual selection. `<C-b>` costs the page-back
-- scroll in visual mode, which `<C-u>` still covers.
-- `<C-i>` is the same byte as `<Tab>`, so Tab italicises too;
-- `<C-`>` is not an ASCII control code and needs a terminal
-- speaking the kitty keyboard protocol.
vim.api.nvim_create_autocmd("FileType", {
	pattern = "markdown",
	callback = function(args)
		local emphasis = {
			{ "<C-b>", "**", "bold" },
			{ "<C-i>", "*", "italic" },
			{ "<C-`>", "`", "inline code" },
		}
		for _, e in ipairs(emphasis) do
			vim.keymap.set("x", e[1], "c" .. e[2] .. '<C-r>"' .. e[2] .. "<Esc>", {
				buffer = args.buf,
				silent = true,
				desc = "Markdown: " .. e[3] .. " selection",
			})
		end
	end,
})
