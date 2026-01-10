-- World Scanner Module (Cactus Dev Client)
-- Dev / QA world inspection tool
-- Scanning + classification + visual overlay

local Scanner = {}

function Scanner.Init(Client)

	-- =========================
	-- Services / Core
	-- =========================

	local Players = Client.Services.Players
	local RunService = Client.Services.RunService
	local CollectionService = game:GetService("CollectionService")

	local LocalPlayer = Client.Player
	local Page = Client.Pages.WorldScanner
	local Theme = Client.Theme

	-- =========================
	-- State
	-- =========================

	Scanner.Enabled = true

	Scanner.Categories = {
		Players = {Enabled=false, Cache={}, Visuals={}},
		NPCs = {Enabled=false, Cache={}, Visuals={}},
		Interactables = {Enabled=false, Cache={}, Visuals={}},
		Spawns = {Enabled=false, Cache={}, Visuals={}},
		WorldParts = {Enabled=false, Cache={}, Visuals={}}
	}

	Scanner.Loops = {}
	Scanner.Gui = {}

	-- =========================
	-- Utility
	-- =========================

	local function ClearTable(t)
		for k in pairs(t) do
			t[k] = nil
		end
	end

	local function GetRoot()
		local char = LocalPlayer.Character
		return char and char:FindFirstChild("HumanoidRootPart")
	end

	local function DistanceFromPlayer(pos)
		local root = GetRoot()
		if not root then return math.huge end
		return (root.Position - pos).Magnitude
	end

	-- =========================
	-- Highlight System
	-- =========================

	function Scanner:AddHighlight(inst, color)
		if not inst or not inst:IsDescendantOf(workspace) then return end

		local h = Instance.new("Highlight")
		h.Adornee = inst
		h.FillTransparency = 1
		h.OutlineTransparency = 0.15
		h.OutlineColor = color or Theme.STROKE
		h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		h.Parent = inst

		return h
	end

	function Scanner:ClearVisuals(category)
		for _,v in pairs(self.Categories[category].Visuals) do
			if v and v.Destroy then
				pcall(function() v:Destroy() end)
			end
		end
		ClearTable(self.Categories[category].Visuals)
	end

	-- =========================
	-- Nearest Object
	-- =========================

	function Scanner:GetNearest(category)
		local nearest, best = nil, math.huge

		for _,inst in pairs(self.Categories[category].Cache) do
			local pos =
				inst:IsA("Model") and inst.PrimaryPart and inst.PrimaryPart.Position
				or inst:IsA("BasePart") and inst.Position

			if pos then
				local d = DistanceFromPlayer(pos)
				if d < best then
					best = d
					nearest = inst
				end
			end
		end

		return nearest, best
	end

	-- =========================
	-- Scan Logic
	-- =========================

	function Scanner:ScanPlayers()
		local list = {}
		for _,plr in pairs(Players:GetPlayers()) do
			if plr ~= LocalPlayer and plr.Character then
				table.insert(list, plr.Character)
			end
		end
		self.Categories.Players.Cache = list
	end

	function Scanner:ScanNPCs()
		local list = {}
		for _,m in pairs(workspace:GetDescendants()) do
			if m:IsA("Model") and m:FindFirstChildOfClass("Humanoid") then
				if not Players:GetPlayerFromCharacter(m) then
					table.insert(list, m)
				end
			end
		end
		self.Categories.NPCs.Cache = list
	end

	function Scanner:ScanInteractables()
		local list = {}
		for _,d in pairs(workspace:GetDescendants()) do
			if d:IsA("ProximityPrompt") or d:IsA("ClickDetector") then
				table.insert(list, d.Parent)
			end
		end
		self.Categories.Interactables.Cache = list
	end

	function Scanner:ScanSpawns()
		local list = {}

		for _,d in pairs(workspace:GetDescendants()) do
			if d:IsA("SpawnLocation") then
				table.insert(list, d)
			elseif d:IsA("BasePart") then
				local n = string.lower(d.Name)
				if string.find(n,"spawn") or string.find(n,"zone") or string.find(n,"area") then
					table.insert(list, d)
				end
			end
		end

		for _,tag in pairs(CollectionService:GetTagged("Spawn")) do
			table.insert(list, tag)
		end

		self.Categories.Spawns.Cache = list
	end

	function Scanner:ScanWorldParts()
		local list = {}
		for _,p in pairs(workspace:GetDescendants()) do
			if p:IsA("BasePart") and p.Anchored then
				if p.Size.Magnitude > 40 then
					table.insert(list, p)
				end
			end
		end
		self.Categories.WorldParts.Cache = list
	end

	-- =========================
	-- Visual Refresh
	-- =========================

	function Scanner:RefreshVisuals(category)
		self:ClearVisuals(category)

		for _,inst in pairs(self.Categories[category].Cache) do
			local h = self:AddHighlight(inst, Theme.STROKE)
			if h then
				table.insert(self.Categories[category].Visuals, h)
			end
		end
	end

	-- =========================
	-- Loops
	-- =========================

	function Scanner:Start(category, scanFunc)
		if self.Loops[category] then return end

		self.Categories[category].Enabled = true

		self.Loops[category] = task.spawn(function()
			while self.Categories[category].Enabled do
				pcall(function()
					self[scanFunc](self)
					self:RefreshVisuals(category)
				end)
				task.wait(2)
			end
		end)
	end

	function Scanner:Stop(category)
		self.Categories[category].Enabled = false
		self.Loops[category] = nil
		self:ClearVisuals(category)
		ClearTable(self.Categories[category].Cache)
	end

	-- =========================
	-- GUI (minimal base)
	-- =========================

	local function MakeRow(name, y, onToggle)

		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(1,-12,0,26)
		btn.Position = UDim2.new(0,6,0,y)
		btn.BackgroundColor3 = Theme.BUTTON
		btn.Text = name.." : OFF"
		btn.TextColor3 = Theme.TEXT_DIM
		btn.Font = Enum.Font.Code
		btn.TextSize = 14
		btn.Parent = Page

		local c = Instance.new("UICorner", btn)
		c.CornerRadius = UDim.new(0,6)

		btn.MouseButton1Click:Connect(function()
			onToggle(btn)
		end)

		return btn
	end

	-- =========================
	-- GUI Rows
	-- =========================

	local y = 10

	Scanner.Gui.Players = MakeRow("Players", y, function(b)
		if not Scanner.Categories.Players.Enabled then
			Scanner:Start("Players","ScanPlayers")
			b.Text = "Players : ON"
			b.TextColor3 = Theme.TEXT
		else
			Scanner:Stop("Players")
			b.Text = "Players : OFF"
			b.TextColor3 = Theme.TEXT_DIM
		end
	end)

	y += 32

	Scanner.Gui.NPCs = MakeRow("NPCs", y, function(b)
		if not Scanner.Categories.NPCs.Enabled then
			Scanner:Start("NPCs","ScanNPCs")
			b.Text = "NPCs : ON"
			b.TextColor3 = Theme.TEXT
		else
			Scanner:Stop("NPCs")
			b.Text = "NPCs : OFF"
			b.TextColor3 = Theme.TEXT_DIM
		end
	end)

	y += 32

	Scanner.Gui.Interactables = MakeRow("Interactables", y, function(b)
		if not Scanner.Categories.Interactables.Enabled then
			Scanner:Start("Interactables","ScanInteractables")
			b.Text = "Interactables : ON"
			b.TextColor3 = Theme.TEXT
		else
			Scanner:Stop("Interactables")
			b.Text = "Interactables : OFF"
			b.TextColor3 = Theme.TEXT_DIM
		end
	end)

	y += 32

	Scanner.Gui.Spawns = MakeRow("Spawns / Zones", y, function(b)
		if not Scanner.Categories.Spawns.Enabled then
			Scanner:Start("Spawns","ScanSpawns")
			b.Text = "Spawns : ON"
			b.TextColor3 = Theme.TEXT
		else
			Scanner:Stop("Spawns")
			b.Text = "Spawns : OFF"
			b.TextColor3 = Theme.TEXT_DIM
		end
	end)

	y += 32

	Scanner.Gui.World = MakeRow("World Parts", y, function(b)
		if not Scanner.Categories.WorldParts.Enabled then
			Scanner:Start("WorldParts","ScanWorldParts")
			b.Text = "World : ON"
			b.TextColor3 = Theme.TEXT
		else
			Scanner:Stop("WorldParts")
			b.Text = "World : OFF"
			b.TextColor3 = Theme.TEXT_DIM
		end
	end)

end

return Scanner
