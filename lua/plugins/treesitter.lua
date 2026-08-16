-- TREESITTER
--------------------------------------------------
-- Grammars come from nix (module.nix): nothing is
-- compiled at runtime, so no gcc in the build.

return {
	{
		"nvim-treesitter",

		enabled = true,
		auto_enable = false,
		lazy = true,

		event = { "BufReadPost", "BufNewFile" },

		dep_of = { "codecompanion.nvim", "image.nvim" },

		after = function()
			---@param buf integer
			---@param language string
			local function treesitter_try_attach(buf, language)
				-- No parser, no action: nothing is ever downloaded
				if not vim.treesitter.language.add(language) then
					return false
				end

				vim.treesitter.start(buf, language)

				-- Treesitter-based folds, open by default
				vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
				vim.wo.foldmethod = "expr"
				vim.o.foldlevel = 99

				-- Treesitter-based indentation
				vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"

				return true
			end

			vim.api.nvim_create_autocmd("FileType", {
				callback = function(args)
					local buf, filetype = args.buf, args.match
					local language = vim.treesitter.language.get_lang(filetype)
					if not language then
						return
					end
					treesitter_try_attach(buf, language)
				end,
			})
		end,
	},
	{
		"nvim-treesitter-textobjects",

		enabled = true,
		auto_enable = true,
		lazy = true,

		event = { "BufReadPost", "BufNewFile" },

		before = function()
			-- Avoid clashes with the builtin ftplugin maps
			vim.g.no_plugin_maps = true
		end,

		after = function()
			require("nvim-treesitter-textobjects").setup({
				select = {
					-- Jump forward to the nearest textobject
					lookahead = true,
					selection_modes = {
						["@parameter.outer"] = "v", -- characters
						["@function.outer"] = "V", -- lines
					},
					include_surrounding_whitespace = false,
				},
			})

			-- Textobjects --
			vim.keymap.set({ "x", "o" }, "am", function()
				require("nvim-treesitter-textobjects.select").select_textobject("@function.outer", "textobjects")
			end, { desc = "Function (outer)" })
			vim.keymap.set({ "x", "o" }, "im", function()
				require("nvim-treesitter-textobjects.select").select_textobject("@function.inner", "textobjects")
			end, { desc = "Function (inner)" })
			vim.keymap.set({ "x", "o" }, "ac", function()
				require("nvim-treesitter-textobjects.select").select_textobject("@class.outer", "textobjects")
			end, { desc = "Class (outer)" })
			vim.keymap.set({ "x", "o" }, "ic", function()
				require("nvim-treesitter-textobjects.select").select_textobject("@class.inner", "textobjects")
			end, { desc = "Class (inner)" })
			vim.keymap.set({ "x", "o" }, "as", function()
				require("nvim-treesitter-textobjects.select").select_textobject("@local.scope", "locals")
			end, { desc = "Local scope" })

			-- Parameter swap: `<leader>a` belongs to CodeCompanion
			vim.keymap.set("n", "<leader>ps", function()
				require("nvim-treesitter-textobjects.swap").swap_next("@parameter.inner")
			end, { desc = "Swap with next parameter" })
			vim.keymap.set("n", "<leader>pS", function()
				require("nvim-treesitter-textobjects.swap").swap_previous("@parameter.outer")
			end, { desc = "Swap with previous parameter" })
		end,
	},
}
