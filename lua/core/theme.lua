-- TRANSPARENT BACKGROUND
--------------------------------------------------
-- The palette lives in lua/plugins/dankcolors.lua. This
-- module only strips the background off highlight groups.

vim.api.nvim_create_autocmd({ "ColorScheme", "VimEnter" }, {
	pattern = "*",
	desc = "Force transparent background for UI elements",
	callback = function()
		-- Drop the background only, keep fg and styles
		local function set_transparent(group)
			---@type any
			local hl = vim.api.nvim_get_hl(0, { name = group, link = false })
			if not hl or vim.tbl_isempty(hl) then
				return
			end
			hl.bg = nil
			hl.ctermbg = nil
			hl.force = true
			vim.api.nvim_set_hl(0, group, hl)
		end

		-- Core, UI and plugin groups
		local groups = {
			"Normal",
			"NormalNC",
			"StatusLine",
			"StatusLineNC",
			"EndOfBuffer",
			"CmpItemAbbr",
			"CmpItemAbbrDeprecated",
			"CmpItemAbbrMatch",
			"CmpDocumentation",
			"CmpDocumentationBorder",
			"NormalFloat",
			"FloatBorder",
			"Pmenu",
			"PmenuBorder",
			"TelescopeNormal",
			"FidgetNormal",
			"FidgetBorder",
			"WhichKey",
			"WhichKeyFloat",
			"WhichKeyGroup",
			"LazyNormal",
			"MasonNormal",
			"DiagnosticVirtualTextError",
			"DiagnosticVirtualTextWarn",
			"DiagnosticVirtualTextInfo",
			"DiagnosticVirtualTextHint",
			"TreesitterContext",
			"TreesitterContextLineNumber",
			"SignColumn",
			"ColorColumn",
			"CursorLineSign",
			"FoldColumn",
			-- Diff* groups stay out: clearing them here would
			-- leave diffs with no colour at all
			--"DiffAdd", "DiffChange", "DiffDelete", "DiffText",
		}

		-- Generate every gitsigns group combination
		local git_prefixes = { "GitSigns", "GitSignsStaged" }
		local git_actions = { "Add", "Change", "Delete", "Untracked", "Changedelete", "Topdelete" }
		local git_suffixes = { "", "Nr", "Ln", "Cul" }

		for _, prefix in ipairs(git_prefixes) do
			for _, action in ipairs(git_actions) do
				for _, suffix in ipairs(git_suffixes) do
					table.insert(groups, prefix .. action .. suffix)
				end
			end
		end

		for _, group in ipairs(groups) do
			set_transparent(group)
		end

		-- Links between groups
		local links = {
			LazyButtonActive = "Visual",
			LazyH1 = "Title",
			LazySpecial = "Constant",
			PmenuSel = "Visual",
			TelescopeSelection = "Visual",
		}

		for from, to in pairs(links) do
			vim.api.nvim_set_hl(0, from, { link = to })
		end

		-- Telescope: clear the background only, not the text
		local telescope_groups = {
			"TelescopeBorder",
			"TelescopeResultsBorder",
			"TelescopeResultsTitle",
			"TelescopePromptBorder",
			"TelescopePromptTitle",
			"TelescopePreviewBorder",
			"TelescopePreviewTitle",
			"TelescopePromptNormal",
			"TelescopePreviewNormal",
			"TelescopeResultsNormal",
			"TelescopePromptPrefix",
		}

		for _, group in ipairs(telescope_groups) do
			vim.api.nvim_set_hl(0, group, { bg = nil, ctermbg = nil })
		end
	end,
})

-- Force a first run at startup
vim.cmd("doautocmd ColorScheme")
