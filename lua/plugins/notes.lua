-- NOTES (settings.obsidian.enable)
--------------------------------------------------
-- The vault is set from nix via `settings.obsidian.vault`.
-- Without one the plugin stays out of the build, so no
-- path is guessed and no folder is created in whatever
-- directory you happen to open the editor from.
-- Subfolders are obsidian.nvim's own defaults, relative
-- to the vault: none is imposed here.

return {
	"obsidian.nvim",

	for_cat = "obsidian",
	auto_enable = false,
	lazy = true,

	ft = { "markdown" },
	cmd = { "Obsidian" },

	keys = {
		{ "<leader>os", "<cmd>Obsidian search<cr>", desc = "[O]bsidian [S]earch" },
		{ "<leader>oo", "<cmd>Obsidian quick_switch<cr>", desc = "[O]bsidian [O]pen Note" },
		{ "<leader>on", "<cmd>Obsidian new<cr>", desc = "[O]bsidian [N]ew Note" },
		{ "<leader>ot", "<cmd>Obsidian template<cr>", desc = "[O]bsidian [T]emplate" },
		{ "<leader>ob", "<cmd>Obsidian backlinks<cr>", desc = "[O]bsidian [B]acklinks" },
		{ "<leader>ol", "<cmd>Obsidian links<cr>", desc = "[O]bsidian [L]inks" },
		{ "<leader>otg", "<cmd>Obsidian tags<cr>", desc = "[O]bsidian [T]a[G]s" },
		{ "<leader>od", "<cmd>Obsidian dailies<cr>", desc = "[O]bsidian [D]ailies" },
		{ "<leader>odtd", "<cmd>Obsidian today<cr>", desc = "[O]bsidian Today" },
		{ "<leader>ody", "<cmd>Obsidian yesterday<cr>", desc = "[O]bsidian Yesterday" },
		{ "<leader>odtm", "<cmd>Obsidian tomorrow<cr>", desc = "[O]bsidian Tomorrow" },
		{ "<leader>orn", "<cmd>Obsidian rename<cr>", desc = "[O]bsidian [R]ename note and links" },
		{ "<leader>opi", "<cmd>Obsidian paste_img<cr>", desc = "[O]bsidian [P]aste [I]mage" },
		{ "<leader>og", "<cmd>Obsidian open<cr>", desc = "[O]bsidian [G]ui open" },
		{ "<leader>ow", "<cmd>Obsidian workspace<cr>", desc = "[O]bsidian [W]orkspace Switch" },
		{ "gf", "<cmd>Obsidian follow_link vsplit<cr>", desc = "Follow Anchor Link" },
		{ "<leader>ovs", "<cmd>Obsidian follow_link vsplit<cr>", desc = "Open link in vsplit" },
		{ "<leader>ohs", "<cmd>Obsidian follow_link hsplit<cr>", desc = "Open link in hsplit" },
		{
			"<leader>ol",
			"<cmd>Obsidian link<cr>",
			mode = "v",
			desc = "Link selection",
		},
		{
			"<leader>onl",
			"<cmd>Obsidian link_new<cr>",
			mode = "v",
			desc = "New note from selection",
		},
	},

	after = function()
		local vault = nixInfo("", "settings", "obsidian", "vault")
		if vault == "" then
			return
		end

		local path = vim.fs.normalize(vim.fn.expand(vault))

		require("obsidian").setup({
			legacy_commands = false,
			-- TRACE wrote a huge log on every event
			log_level = vim.log.levels.WARN,
			ui = {
				enable = false,
			},
			workspaces = {
				{
					name = vim.fn.fnamemodify(path, ":t"),
					path = path,
				},
			},
			note_id_func = function(title)
				local suffix = ""
				if title ~= nil then
					suffix = title:gsub(" ", "_"):gsub("[^A-Za-z0-9-]", ""):lower()
				else
					for _ = 1, 4 do
						suffix = suffix .. string.char(math.random(65, 90))
					end
				end
				return tostring(os.time()) .. "_" .. suffix
			end,
			link = {
				style = "markdown",
			},
			frontmatter = {
				enabled = true,
				func = function(note)
					if note.title then
						note:add_alias(note.title)
					end
					local out = { id = note.id, aliases = note.aliases, tags = note.tags }
					if note.metadata ~= nil and not vim.tbl_isempty(note.metadata) then
						for k, v in pairs(note.metadata) do
							out[k] = v
						end
					end
					return out
				end,
			},
			open = {
				use_advanced_uri = false,
				-- Delegates to tools/open.lua
				func = function(uri)
					vim.ui.open(uri)
				end,
			},
			picker = {
				name = "telescope.nvim",
				note_mappings = {
					new = "<C-x>",
					insert_link = "<C-l>",
				},
				tag_mappings = {
					tag_note = "<C-x>",
					insert_tag = "<C-l>",
				},
			},
			search = {
				max_lines = 1000,
				sort_by = "modified",
				sort_reversed = true,
			},
			open_notes_in = "current",
		})
	end,
}
