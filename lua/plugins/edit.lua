-- EDITING
--------------------------------------------------
-- Small helpers for writing code.

return {
	-- Indentation inferred from the file --
	{
		"vim-sleuth",

		enabled = true,
		auto_enable = true,
		lazy = false,
	},

	-- Wrap the selection in delimiters (`S` in visual)
	{
		"nvim-surround",

		enabled = true,
		auto_enable = false,
		lazy = true,

		version = "^4.0.0",
		event = "DeferredUIEnter",

		after = function()
			require("nvim-surround").setup({})
		end,
	},

	-- Auto-close brackets and quotes --
	{
		"nvim-autopairs",

		enabled = true,
		auto_enable = false,
		lazy = true,

		event = { "InsertEnter" },

		after = function()
			require("nvim-autopairs").setup({})
			local cmp_autopairs = require("nvim-autopairs.completion.cmp")
			local cmp = require("cmp")
			cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())
		end,
	},

	-- Preview code actions in the picker --
	{
		"actions-preview.nvim",

		enabled = true,
		auto_enable = false,
		lazy = true,

		dep_of = { "telescope.nvim" },
		keys = {
			{
				"<leader>ca",
				function()
					require("actions-preview").code_actions()
				end,
				mode = { "v", "n" },
				desc = "Code Actions Preview",
			},
		},
	},

	-- Search and replace across files --
	{
		"nvim-spectre",

		enabled = true,
		auto_enable = true,
		lazy = true,

		cmd = { "Spectre" },
		-- Uppercase so telescope keeps the lowercase maps
		keys = {
			{
				"<leader>S",
				function()
					require("spectre").toggle()
				end,
				mode = "n",
				desc = "Toggle Spectre",
			},
			{
				"<leader>sR",
				function()
					require("spectre").open_visual({ select_word = true })
				end,
				mode = "n",
				desc = "Spectre: word under cursor",
			},
			{
				"<leader>sR",
				function()
					require("spectre").open_visual()
				end,
				mode = "v",
				desc = "Spectre: selection",
			},
			{
				"<leader>sF",
				function()
					require("spectre").open_file_search({ select_word = true })
				end,
				mode = "n",
				desc = "Spectre: current file only",
			},
		},
	},

	-- Undo history as a tree --
	{
		"undotree",

		enabled = true,
		auto_enable = true,
		lazy = true,

		cmd = { "UndotreeToggle" },
		keys = {
			{ "<leader>u", "<cmd>UndotreeToggle<cr>", mode = "n", desc = "Toggle UndoTree" },
		},
	},

	-- Types and completion for nvim's own lua config --
	{
		"lazydev.nvim",

		enabled = true,
		auto_enable = false,
		lazy = true,

		ft = "lua",

		after = function(plugin)
			require("lazydev").setup(plugin.opts)
		end,
		opts = {
			library = {
				{ path = "luvit-meta/library", words = { "vim%.uv" } },
			},
		},
	},

	-- Library shared by many plugins --
	{
		"plenary.nvim",

		enabled = true,
		auto_enable = true,
		lazy = true,

		dep_of = { "todo-comments.nvim", "lazygit.nvim", "telescope.nvim", "obsidian.nvim", "codecompanion.nvim" },
	},
}
