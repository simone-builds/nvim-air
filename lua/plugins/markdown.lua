-- MARKDOWN
--------------------------------------------------
-- In-buffer rendering and inline images. Browser preview
-- (markdown-preview.nvim) was dropped: it pulls in about
-- 300 MB of nodejs.
--
-- No colour is named here. `MdAccent` and `MdSoft` come from
-- lua/core/theme.lua, which derives them from the desktop
-- palette, so the buffer follows the wallpaper.

local nerd = require("core.setting").bool(true, "settings", "nerd_font", "enable")

-- Heading markers. The numbered circles state the level at a
-- glance, which hashes do not: counting `####` is work, and
-- with `position = "overlay"` the marker is all you see.
-- Without a Nerd Font the glyphs would be empty boxes, so
-- the hashes come back.
local heading_icons = nerd and { "󰲡 ", "󰲣 ", "󰲥 ", "󰲧 ", "󰲩 ", "󰲫 " }
	or { "# ", "## ", "### ", "#### ", "##### ", "###### " }

return {
	-- Colours, icons and layout inside the buffer --
	{
		"render-markdown.nvim",

		enabled = true,
		auto_enable = false,
		lazy = true,

		ft = { "markdown" },

		-- Emphasis colours used to be set from a ColorScheme
		-- autocmd registered here. It never fired: this runs
		-- when the first .md buffer opens, long after the
		-- colorscheme was applied. They live in core/theme.lua now.
		after = function(plugin)
			require("render-markdown").setup(plugin.opts or {})
		end,

		opts = {
			heading = {
				enabled = true,
				sign = true,
				position = "overlay",
				icons = heading_icons,
				signs = { "󰫎 " },
				width = "full",
				left_margin = 0,
				left_pad = 0,
				right_pad = 0,
				min_width = 0,
				border = false,
				border_virtual = false,
				border_prefix = false,
				above = "▁",
				below = "▔",
				backgrounds = {},
				-- All six levels share one group: the glyph
				-- already says which level it is
				foregrounds = {
					"MdHeading",
					"MdHeading",
					"MdHeading",
					"MdHeading",
					"MdHeading",
					"MdHeading",
				},
			},
			paragraph = {
				enabled = false,
				left_margin = 0,
				min_width = 0,
			},
			code = {
				enabled = true,
				sign = true,
				style = "full",
				position = "left",
				language_pad = 0,
				language_name = true,
				disable_background = { "diff" },
				width = "full",
				left_margin = 0,
				left_pad = 0,
				right_pad = 0,
				min_width = 0,
				border = "thick",
				above = "▄",
				below = "▀",
				highlight = "RenderMarkdownCode",
				highlight_info = "RenderMarkdownCode",
				highlight_language = nil,
				highlight_border = false,
				highlight_fallback = "RenderMarkdownCodeFallback",
				highlight_inline = "RenderMarkdownCodeInline",
			},
			dash = {
				enabled = true,
				icon = "─",
				width = "full",
				highlight = "RenderMarkdownDash",
			},
			bullet = {
				enabled = true,
				-- One glyph per nesting level. These were four
				-- spaces: the marker was drawn as blank, so the
				-- `-` looked missing everywhere except under the
				-- cursor and inside a visual selection, the two
				-- places anti-conceal turns rendering off.
				-- Plain Unicode, no Nerd Font needed. The second
				-- level is U+2B29 BLACK SMALL DIAMOND, not the
				-- full-size U+25C6: it has to match the weight
				-- of the bullet above it, not outshout it.
				icons = { "•", "⬩", "-", "-" },
				ordered_icons = function(ctx)
					local value = vim.trim(ctx.value)
					local index = tonumber(value:sub(1, #value - 1))
					return string.format("%d.", index > 1 and index or ctx.index)
				end,
				left_pad = 0,
				right_pad = 0,
				highlight = "MdAccent",
			},
			checkbox = {
				enabled = true,
				unchecked = {
					icon = "",
					highlight = "MdAccent",
				},
				checked = {
					icon = "󰄲",
					highlight = "MdAccent",
				},
				custom = {
					todo = { raw = "[-]", rendered = "󰥔 ", highlight = "MdSoft", scope_highlight = nil },
					important = { raw = "[~]", rendered = "󰓎 ", highlight = "DiagnosticWarn" },
				},
			},
			quote = {
				enabled = true,
				icon = "▋",
				repeat_linebreak = true,
				highlight = "RenderMarkdownQuote",
			},
			pipe_table = {
				enabled = true,
				preset = "round",
				style = "full",
				cell = "padded",
				padding = 1,
				min_width = 0,
				alignment_indicator = "━",
				head = "RenderMarkdownTableHead",
				row = "RenderMarkdownTableRow",
			},
			callout = {},
			link = {
				enabled = true,
				footnote = {
					superscript = true,
					prefix = "",
					suffix = "",
				},
				image = "󰥶 ",
				email = "󰀓 ",
				hyperlink = "󰌹 ",
				highlight = "RenderMarkdownLink",
				wiki = { icon = "󱗖 ", highlight = "RenderMarkdownWikiLink" },
				custom = {
					web = { pattern = "^http", icon = "󰖟 " },
					youtube = { pattern = "youtube%.com", icon = "󰗃 " },
					github = { pattern = "github%.com", icon = "󰊤 " },
					neovim = { pattern = "neovim%.io", icon = " " },
					stackoverflow = { pattern = "stackoverflow%.com", icon = "󰓌 " },
					discord = { pattern = "discord%.com", icon = "󰙯 " },
					reddit = { pattern = "reddit%.com", icon = "󰑍 " },
				},
			},
			sign = {
				enabled = true,
				highlight = "RenderMarkdownSign",
			},
			indent = {
				enabled = false,
				per_level = 2,
				skip_level = 1,
				skip_heading = true,
			},
			-- Rendering formulas would need an external
			-- converter that is not in the build
			latex = {
				enabled = false,
			},
		},
	},

	-- Inline images (requires imagemagick) --
	{
		"image.nvim",

		enabled = require("core.setting").bool(true, "settings", "markdown", "images", "enable"),
		auto_enable = false,
		lazy = true,

		ft = { "markdown" },

		event = {
			"BufReadPre *.png",
			"BufReadPre *.jpg",
			"BufReadPre *.jpeg",
			"BufReadPre *.gif",
			"BufReadPre *.webp",
			"BufReadPre *.avif",
		},

		after = function(plugin)
			require("image").setup(plugin.opts)
		end,

		opts = {
			-- `kitty` also covers WezTerm: same protocol
			backend = nixInfo("kitty", "settings", "render-backend"),
			processor = "magick_cli",
			integrations = {
				markdown = {
					enabled = true,
					clear_in_insert_mode = false,
					download_remote_images = false,
					only_render_image_at_cursor = true,
					floating_windows = true,
					filetypes = { "markdown" },
					resolve_image_path = function(document_path, image_path, fallback)
						return fallback(document_path, image_path)
					end,
				},
				html = { enabled = false },
				css = { enabled = false },
			},
			max_width = nil,
			max_height = nil,
			max_width_window_percentage = nil,
			max_height_window_percentage = 70,
			window_overlap_clear_enabled = false,
			window_overlap_clear_ft_ignore = { "cmp_menu", "cmp_docs", "snacks_notif", "scrollview", "scrollview_sign" },
			editor_only_render_when_focused = false,
			tmux_show_only_in_active_window = false,
			hijack_file_patterns = { "*.png", "*.jpg", "*.jpeg", "*.gif", "*.webp", "*.avif" },
		},
	},
}
