-- AI CHAT (settings.ai.enable)
--------------------------------------------------
-- CodeCompanion. The adapter comes from `settings.ai.adapter`
-- and nothing else is configured here, so no credential ever
-- lives in this repository.

return {
	"codecompanion.nvim",

	for_cat = "ai",
	auto_enable = false,
	lazy = true,

	cmd = {
		"CodeCompanion",
		"CodeCompanionActions",
		"CodeCompanionChat",
		"CodeCompanionAdd",
	},

	keys = {
		{
			"<C-s>",
			"<cmd>CodeCompanionActions<cr>",
			mode = { "n", "v" },
			desc = "CodeCompanion Actions",
		},
		{
			"<leader>a",
			"<cmd>CodeCompanionChat Toggle<cr>",
			mode = { "n", "v" },
			desc = "Toggle CodeCompanion Chat",
		},
		{
			"ga",
			"<cmd>CodeCompanionAdd<cr>",
			mode = "v",
			desc = "Add to CodeCompanion",
		},
	},

	after = function()
		local adapter = nixInfo("copilot", "settings", "ai", "adapter")

		require("codecompanion").setup({
			strategies = {
				chat = { adapter = adapter },
				inline = { adapter = adapter },
				cmd = { adapter = adapter },
			},
		})
	end,
}
