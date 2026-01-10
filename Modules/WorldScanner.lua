-- WorldScanner.lua
-- Cactus Client – Dev / QA World Scanner
-- World inspection + classification + visual debug

local WorldScanner = {}

function WorldScanner.Init(Client)

	-- =========================
	-- Core
	-- =========================

	local Players = Client.Services.Players
	local RunService = Client.Services.RunService
	local LocalPlayer = Client.Player
	local Theme = Client.Theme
	local Page = Client.Pages.WorldScanner

	if not Page then
		warn("[WorldScanner] Page not found")
		return
	end

	Page:ClearAllChildren()

	-- =========================
	-- Config
	-- =========================

	local SCAN_INTERVAL = 2

	local CategoryColors = {
		Spawns = Color3.fromRGB(0,255,120),
		NPCs = Color3.fromRGB(0,200,255),
		Interactables = Color3.fromRGB(255,200,0),
		WorldParts = Color3.fromRGB(180,180,180),
	}

	-- =========================
	-- State
	-- =========================

	local State = {
		Spawns = false,
		NPCs = false,
		Interactables = false,
		WorldParts = false,
	}

	local Cache = {
		Spawns = {},
		NPCs = {},
		Interactables = {},
		WorldParts = {},
	}

	local Visuals = {
		Spawns = {},
		NPCs = {},
		Interactables = {},
		WorldParts = {},
	}

	local Loops = {}

	-- =========================
	-- Utils
	-- =========================

	local function clear(tbl)
		for k in pairs(tbl) do tbl[k] = nil end
	end

	local function getRoot()
		local c = LocalPlayer.Character
		return c and c:FindFirstChild("HumanoidRootPart")
	end

	local function distanceFromPlayer(pos)
		local r = getRoot()
		if not r then return math.huge end
		return (r.Position - pos).Magnitude
	end

	local function getPosition(inst)
		if inst:IsA("Model") then
			return inst.PrimaryPart and inst.PrimaryPart.Position
		elseif inst:IsA("BasePart") then
			return inst.Position
		end
	end

	-- =========================
	-- Highlight system
	-- =========================

	local function addHighlight(inst, color)
		if not inst or not inst:IsDescendantOf(workspace) then return end

		local h = Instance.new("Highlight")
		h.Adornee = inst
		h.FillTransparency = 1
		h.OutlineTransparency = 0.15
		h.OutlineColor = color
		h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		h.Parent = inst

		return h
	end

	local function clearVisuals(name)
		for _,h in pairs(Visuals[name]) do
			pcall(function() h:Destroy() end)
		end
		clear(Visuals[name])
	end

	-- =========================
	-- Nearest
	-- =========================

	local function getNearest(name)
		local best, chosen = math.huge, nil

		for _,inst in pairs(Cache[name]) do
			local pos = getPosition(inst)
			if pos then
				local d = distanceFromPlayer(pos)
				if d < best then
					best = d
					chosen = inst
				end
			end
		end

		return chosen, best
	end

	-- =========================
	-- Scan logic
	-- =========================

	local function scanSpawns()
		clear(Cache.Spawns)

		for _,d in pairs(workspace:GetDescendants()) do
			if d:IsA("SpawnLocation") then
				table.insert(Cache.Spawns, d)

			elseif d:IsA("BasePart") then
				local n = d.Name:lower()
				if n:find("spawn") or n:find("zone") or n:find("area") then
					table.insert(Cache.Spawns, d)
				end
			end
		end
	end

	local function scanNPCs()
		clear(Cache.NPCs)

		for _,m in pairs(workspace:GetDescendants()) do
			if m:IsA("Model") and m:FindFirstChildOfClass("Humanoid") then
				if not Players:GetPlayerFromCharacter(m) then
					table.insert(Cache.NPCs, m)
				end
			end
		end
	end

	local function scanInteractables()
		clear(Cache.Interactables)

		for _,d in pairs(workspace:GetDescendants()) do
			if d:IsA("ProximityPrompt") or d:IsA("ClickDetector") then
				if d.Parent then
					table.insert(Cache.Interactables, d.Parent)
				end
			end
		end
	end

	local function scanWorldParts()
		clear(Cache.WorldParts)

		for _,p in pairs(workspace:GetDescendants()) do
			if p:IsA("BasePart") and p.Anchored and p.Size.Magnitude > 40 then
				table.insert(Cache.WorldParts, p)
			end
		end
	end

	local ScanFunctions = {
		Spawns = scanSpawns,
		NPCs = scanNPCs,
		Interactables = scanInteractables,
		WorldParts = scanWorldParts,
	}

	-- =========================
	-- Loop control
	-- =========================

	local function startScan(name)
		if Loops[name] then return end
		State[name] = true

		Loops[name] = task.spawn(function()
			while State[name] do
				pcall(function()
					ScanFunctions[name]()
					clearVisuals(name)

					for _,inst in pairs(Cache[name]) do
						local h = addHighlight(inst, CategoryColors[name])
						if h then
							table.insert(Visuals[name], h)
						end
					end
				end)
				task.wait(SCAN_INTERVAL)
			end
		end)
	end

	local function stopScan(name)
		State[name] = false
		Loops[name] = nil
		clear(Cache[name])
		clearVisuals(name)
	end

	-- =========================
	-- GUI
	-- =========================

	local Panel = Instance.new("Frame")
	Panel.Size = UDim2.fromOffset(220, 330)
	Panel.BackgroundColor3 = Color3.fromRGB(14,14,14)
	Panel.BorderSizePixel = 0
	Panel.Parent = Page
	Instance.new("UICorner", Panel).CornerRadius = UDim.new(0,10)

	local stroke = Instance.new("UIStroke", Panel)
	stroke.Color = Theme.STROKE
	stroke.Thickness = 1

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1,0,0,26)
	title.BackgroundTransparency = 1
	title.Text = "World Scanner"
	title.Font = Enum.Font.Code
	title.TextSize = 15
	title.TextColor3 = Theme.TEXT
	title.Parent = Panel

	local y = 36
	local infoLabels = {}

	local function makeToggle(label, key)
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(1,-12,0,26)
		btn.Position = UDim2.new(0,6,0,y)
		btn.BackgroundColor3 = Theme.BUTTON
		btn.Text = label .. " : OFF"
		btn.Font = Enum.Font.Code
		btn.TextSize = 13
		btn.TextColor3 = Theme.TEXT_DIM
		btn.Parent = Panel
		Instance.new("UICorner", btn).CornerRadius = UDim.new(0,6)

		local info = Instance.new("TextLabel")
		info.Size = UDim2.new(1,-12,0,18)
		info.Position = UDim2.new(0,6,0,y+26)
		info.BackgroundTransparency = 1
		info.Font = Enum.Font.Code
		info.TextSize = 12
		info.TextXAlignment = Enum.TextXAlignment.Left
		info.TextColor3 = Theme.TEXT_DIM
		info.Text = ""
		info.Parent = Panel

		infoLabels[key] = info

		btn.MouseButton1Click:Connect(function()
			if not State[key] then
				startScan(key)
				btn.Text = label .. " : ON"
				btn.TextColor3 = CategoryColors[key]
			else
				stopScan(key)
				btn.Text = label .. " : OFF"
				btn.TextColor3 = Theme.TEXT_DIM
				info.Text = ""
			end
		end)

		y += 48
	end

	makeToggle("Spawns / Zones", "Spawns")
	makeToggle("NPCs", "NPCs")
	makeToggle("Interactables", "Interactables")
	makeToggle("World Geometry", "WorldParts")

	-- =========================
	-- Info updater
	-- =========================

	task.spawn(function()
		while true do
			for name,label in pairs(infoLabels) do
				if State[name] then
					local nearest, dist = getNearest(name)
					if nearest then
						label.Text = string.format(
							"%d found | nearest: %s (%.1f)",
							#Cache[name],
							nearest.Name,
							dist
						)
					else
						label.Text = #Cache[name] .. " found"
					end
				end
			end
			task.wait(0.4)
		end
	end)
end

return WorldScanner
