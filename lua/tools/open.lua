-- OPENING FILES OUTSIDE THE EDITOR
--------------------------------------------------
-- `vim.ui.open` is what Neovim calls to hand a path or a URL
-- to another program: `gx`, markdown links, `gx` inside Oil.
--
-- Every handler is empty unless `settings.open` sets it, which
-- leaves the built-in behaviour untouched -- xdg-open and the
-- user's own desktop associations decide.

local function handler(key)
	local cmd = nixInfo("", "settings", "open", key)
	if cmd == nil or cmd == "" then
		return nil
	end
	return vim.split(cmd, "%s+", { trimempty = true })
end

local function matches(uri, extensions)
	for _, ext in ipairs(extensions) do
		if vim.endswith(uri:lower(), ext) then
			return true
		end
	end
	return false
end

local IMAGES = { ".png", ".jpg", ".jpeg", ".gif", ".webp", ".avif", ".svg" }
local VIDEOS = { ".mp4", ".mkv", ".webm", ".mov", ".avi" }

vim.ui.open = (function(overridden)
	return function(uri, opt)
		-- An explicit opt from the caller always wins
		if opt and opt.cmd then
			return overridden(uri, opt)
		end

		local cmd
		if uri:match("^%a+://") then
			cmd = handler("browser")
		elseif vim.endswith(uri:lower(), ".pdf") then
			cmd = handler("pdf")
		elseif matches(uri, IMAGES) then
			cmd = handler("image")
		elseif matches(uri, VIDEOS) then
			cmd = handler("video")
		elseif vim.fn.isdirectory(uri) == 1 then
			-- A directory needs both halves: a terminal to run in
			-- and a file manager to run. xdg-open can only reach a
			-- graphical file manager, never a TUI one.
			local term, fm = handler("terminal"), handler("filemanager")
			if term and fm then
				cmd = vim.list_extend(vim.deepcopy(term), fm)
			end
		end

		if cmd then
			opt = vim.tbl_extend("force", opt or {}, { cmd = cmd })
		end
		return overridden(uri, opt)
	end
end)(vim.ui.open)
