-- NIX AND LZE DEBUGGING
--------------------------------------------------

-- List the plugins the Nix wrapper knows about --
vim.api.nvim_create_user_command("LzeNix", function()
	if _G.nixInfo then
		local ok, dbg = pcall(require, "lzextras")
		if ok and dbg.debug then
			dbg.debug.display(nixInfo(nil, "plugins"))
		else
			vim.print(nixInfo(nil, "plugins"))
		end
	end
end, { desc = "Show Nix plugins" })

-- Live load state of every plugin --
vim.api.nvim_create_user_command("LzeStatus", function()
	local rtp = vim.api.nvim_list_runtime_paths()
	local active_plugins = {}

	-- 1. Plugins currently on the runtimepath
	for _, path in ipairs(rtp) do
		local name = path:match("/pack/[^/]+/[^/]+/([^/]+)")
		if not name then
			name = path:match("/nix/store/[a-z0-9]+%-([^/]+)")
		end
		if not name then
			name = path:match("([^/\\]+)$")
		end

		if name then
			name = name:gsub("^vimplugin%-", ""):gsub("^luajit[%w%.%-]+%-", ""):gsub("%-source$", "")
			active_plugins[name] = true
		end
	end

	-- 2. Every installed plugin, by walking the packpath
	local all_plugins = {}
	local packpaths = vim.fn.globpath(vim.o.packpath, "pack/*/*/*", false, true)

	for _, path in ipairs(packpaths) do
		local folder, name = path:match("/pack/[^/]+/([^/]+)/([^/]+)")
		if name then
			name = name:gsub("^vimplugin%-", ""):gsub("^luajit[%w%.%-]+%-", ""):gsub("%-source$", "")
			if name ~= "site" and name ~= "nvim" and name ~= "vim" and name ~= "pack" then
				all_plugins[name] = {
					folder = folder:upper(), -- START or OPT
					is_loaded = active_plugins[name] == true,
				}
			end
		end
	end

	-- Fallback: plugins injected by Nix outside the packpath
	for name, _ in pairs(active_plugins) do
		if not all_plugins[name] and name ~= "site" and name ~= "nvim" and name ~= "vim" and name ~= "pack" then
			all_plugins[name] = { folder = "NIX", is_loaded = true }
		end
	end

	local sorted_names = {}
	for name, _ in pairs(all_plugins) do
		table.insert(sorted_names, name)
	end
	table.sort(sorted_names)

	local lines = {}
	table.insert(lines, string.format(" %-35s | %-6s | %-15s ", "Plugin", "Orig", "State"))
	table.insert(lines, string.rep("-", 65))

	local count_loaded = 0
	local count_total = 0

	for _, name in ipairs(sorted_names) do
		local info = all_plugins[name]
		local status_icon = info.is_loaded and "🟢 LOADED" or "⭕ not loaded"

		if info.is_loaded then
			count_loaded = count_loaded + 1
		end
		count_total = count_total + 1

		table.insert(lines, string.format(" %-35s | %-6s | %-15s ", name, info.folder, status_icon))
	end

	table.insert(lines, string.rep("-", 65))
	table.insert(lines, string.format(" Total: %d installed | %d currently running", count_total, count_loaded))
	table.insert(lines, "")
	table.insert(lines, " (Press 'q' to close) ")

	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	vim.bo[buf].modifiable = false
	vim.bo[buf].readonly = true

	-- Centred floating window
	local width = 70
	local height = math.min(#lines, math.floor(vim.o.lines * 0.8))
	local row = math.floor((vim.o.lines - height) / 2)
	local col = math.floor((vim.o.columns - width) / 2)

	vim.api.nvim_open_win(buf, true, {
		relative = "editor",
		width = width,
		height = height,
		row = row,
		col = col,
		style = "minimal",
		border = "rounded",
		title = " Plugin Monitor ",
		title_pos = "center",
	})

	vim.keymap.set("n", "q", "<Cmd>close<CR>", { buffer = buf, silent = true })
	vim.keymap.set("n", "<Esc>", "<Cmd>close<CR>", { buffer = buf, silent = true })
end, { desc = "Show installed plugins and their load state" })
