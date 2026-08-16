-- PALETTE
--------------------------------------------------
-- Single source of colour for the whole config.
--
-- DankMaterialShell regenerates dms-colors.json from the
-- wallpaper through matugen. That file is the canonical
-- output, the one every DMS integration reads, so it keeps
-- working across template changes on their side.
--
-- Reading the colorscheme DMS generates for Neovim instead
-- (colors/dms.lua) would be the "official" route and is a
-- trap: it requires their AvengeMedia/base46 fork, and the
-- template it comes from already moved once, which is what
-- froze the palette on the old lua/plugins/dankcolors.lua.
--
-- The JSON speaks Material Design 3: `on_surface_variant`,
-- `primary_fixed_dim`. Those name a role in a phone UI, not
-- in an editor, so they are renamed once here and the rest
-- of the config only ever sees `fg`, `accent`, `muted`.

local M = {}

-- SOURCE FILE
--------------------------------------------------

-- DMS writes under the XDG cache; `settings.theme.colors_file`
-- overrides it when the desktop puts it somewhere else.
function M.file()
	local from_nix = nixInfo("", "settings", "theme", "colors_file")
	if type(from_nix) == "string" and from_nix ~= "" then
		return from_nix
	end
	local cache = vim.env.XDG_CACHE_HOME
	if not cache or cache == "" then
		cache = (vim.env.HOME or "~") .. "/.cache"
	end
	return cache .. "/DankMaterialShell/dms-colors.json"
end

-- COLOUR MATHS
--------------------------------------------------

local function to_rgb(hex)
	hex = hex:gsub("#", "")
	return tonumber(hex:sub(1, 2), 16) or 0, tonumber(hex:sub(3, 4), 16) or 0, tonumber(hex:sub(5, 6), 16) or 0
end

-- Mix `top` over `bottom`. `alpha` is how much of `top`
-- survives: 1 keeps it whole, 0 returns `bottom`.
function M.blend(top, bottom, alpha)
	local tr, tg, tb = to_rgb(top)
	local br, bg, bb = to_rgb(bottom)
	local function mix(a, b)
		return math.floor(a * alpha + b * (1 - alpha) + 0.5)
	end
	return string.format("#%02x%02x%02x", mix(tr, br), mix(tg, bg), mix(tb, bb))
end

-- FALLBACK
--------------------------------------------------
-- Outside DMS the config still has to produce a readable
-- editor, so every name has a value even with no JSON.

local fallback = {
	bg = "#14121c",
	bg_dim = "#0f0d17",
	bg_alt = "#201e29",
	bg_high = "#2b2833",
	sel = "#514060",

	fg = "#e6e0ef",
	fg_dim = "#cac4d2",
	muted = "#938f9c",
	border = "#484551",

	accent = "#cbbeff",
	accent_soft = "#e7deff",
	accent_deep = "#4b00d3",
	second = "#d4bee6",
	third = "#e5b7e9",

	red = "#ff7291",
	green = "#7fff99",
	yellow = "#ffd972",
	blue = "#b6a8f2",
	magenta = "#cbbeff",
	cyan = "#e7e1ff",
	white = "#f9f8ff",
	err = "#ffb4ab",
}

-- How much of `accent` survives in `accent_mid`, the colour
-- bold and italic use. It sits between the headings and the
-- prose: 1 lands on the headings, 0 on the body text.
-- Material has no role for that halfway point -- the nearest,
-- `primary_fixed`, is so close to `on_surface` that emphasis
-- would vanish into the paragraph -- so it is mixed here.
local ACCENT_MIX = 0.5

-- LOADING
--------------------------------------------------

local function read_json(path)
	if vim.fn.filereadable(path) ~= 1 then
		return nil
	end
	local ok, data = pcall(function()
		return vim.json.decode(table.concat(vim.fn.readfile(path), "\n"))
	end)
	if not ok or type(data) ~= "table" then
		return nil
	end
	return data
end

-- The palette, with Material role names already translated.
function M.load()
	local p = vim.deepcopy(fallback)
	local data = read_json(M.file())
	local variant = vim.o.background == "light" and "light" or "dark"

	if data then
		local c = (data.colors or {})[variant]
		local d16 = data.dank16 or {}

		-- dank16 entries carry one value per variant too
		local function ansi(name)
			local entry = d16[name]
			if type(entry) ~= "table" then
				return nil
			end
			return entry[variant] or entry.default
		end

		if type(c) == "table" then
			local mapped = {
				-- Surfaces, darkest to lightest
				bg = c.surface,
				bg_dim = c.surface_container_lowest,
				bg_alt = c.surface_container_high,
				bg_high = c.surface_container_highest,
				sel = c.secondary_container,

				-- Text
				fg = c.on_surface,
				fg_dim = c.on_surface_variant,
				muted = c.outline,
				border = c.outline_variant,

				-- Accents. `accent` is the loudest colour of
				-- the theme: headings and list markers use it.
				accent = c.primary,
				accent_soft = c.primary_fixed,
				accent_deep = c.primary_container,
				second = c.secondary,
				third = c.tertiary,
				err = c.error,

				-- Syntax, from the ANSI half of the file
				red = ansi("color1"),
				green = ansi("color2"),
				yellow = ansi("color3"),
				blue = ansi("color4"),
				magenta = ansi("color6"),
				cyan = ansi("color14"),
				white = ansi("color15"),
			}
			for name, value in pairs(mapped) do
				if type(value) == "string" and value:match("^#%x%x%x%x%x%x$") then
					p[name] = value
				end
			end
		end
	end

	p.accent_mid = M.blend(p.accent, p.fg, ACCENT_MIX)
	return p
end

-- BASE16 BRIDGE
--------------------------------------------------
-- base16-nvim wants sixteen slots with fixed meanings: this
-- is the one place where the names go back to being numbers.

function M.base16(p)
	return {
		base00 = p.bg, -- background
		base01 = p.bg_alt, -- panels, folds
		base02 = p.sel, -- selection
		base03 = p.muted, -- comments
		base04 = p.fg_dim, -- secondary text
		base05 = p.fg, -- text
		base06 = p.fg,
		base07 = p.white,
		base08 = p.red, -- variables
		base09 = p.yellow, -- numbers, constants
		base0A = p.accent, -- types
		base0B = p.green, -- strings
		base0C = p.cyan, -- escapes
		base0D = p.accent, -- functions, and Title -> headings
		base0E = p.third, -- keywords
		base0F = p.second,
	}
end

return M
