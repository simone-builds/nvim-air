-- LINTERS
--------------------------------------------------
-- Markdown is absent on purpose: the `rumdl` LSP server
-- covers it without spawning a process on every event.

return {
	"nvim-lint",

	enabled = true,
	auto_enable = false,
	lazy = true,

	ft = { "sh", "bash", "lua", "nix", "python" },

	after = function()
		local lint = require("lint")

		lint.linters_by_ft = {
			sh = { "shellcheck" },
			bash = { "shellcheck" },
			lua = { "selene" },
			nix = { "statix", "deadnix" },
		}

		-- Python only if ruff made it into the build
		if vim.fn.executable("ruff") == 1 then
			lint.linters_by_ft.python = { "ruff" }
		end

		-- Open and save only: BufEnter and InsertLeave kept
		-- restarting the linters constantly (CPU spikes).
		local lint_augroup = vim.api.nvim_create_augroup("lint", { clear = true })
		vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost" }, {
			group = lint_augroup,
			callback = function()
				require("lint").try_lint()
			end,
		})
	end,
}
