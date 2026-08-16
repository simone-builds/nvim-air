-- GIT
--------------------------------------------------
-- The `git` binary is not in the build: it comes from
-- the host PATH.

return {
	-- Change markers in the signcolumn --
	{
		"gitsigns.nvim",

		enabled = true,
		auto_enable = false,
		lazy = true,

		event = { "BufReadPre", "BufNewFile" },

		after = function(plugin)
			require("gitsigns").setup(plugin.opts)
		end,
		opts = {
			current_line_blame = true,
			current_line_blame_opts = {
				virt_text = true,
				virt_text_pos = "eol",
				-- Every blame spawns a git process: 1s is safer
				delay = 1000,
				ignore_whitespace = false,
			},
			current_line_blame_formatter = "<author>, <author_time:%R> - <summary>",
		},
	},

	-- Full git UI in a terminal --
	{
		"lazygit.nvim",

		enabled = true,
		auto_enable = true,
		lazy = true,

		cmd = { "LazyGit", "LazyGitConfig", "LazyGitCurrentFile", "LazyGitFilter", "LazyGitFilterCurrentFile" },
		keys = {
			{ "<leader>gg", "<cmd>LazyGit<cr>", mode = "n", desc = "LazyGit" },
		},
	},

	-- Diffs and file history --
	{
		"diffview.nvim",

		enabled = true,
		auto_enable = false,
		lazy = true,

		cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewFileHistory" },
		keys = {
			{ "<leader>gd", "<cmd>DiffviewOpen<cr>", mode = "n", desc = "Diff View Open" },
			-- `gq` closes: `gc` stays with telescope git_commits
			{ "<leader>gq", "<cmd>DiffviewClose<cr>", mode = "n", desc = "Diff View Close" },
			{ "<leader>gh", "<cmd>DiffviewFileHistory %<cr>", mode = "n", desc = "File History" },
		},

		after = function(plugin)
			require("diffview").setup(plugin.opts)
		end,
		opts = {
			enhanced_diff_hl = true,
			view = { default = { layout = "diff2_horizontal" } },
		},
	},
}
