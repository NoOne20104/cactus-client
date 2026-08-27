--// Cactus Client (Shell v1)

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Prevent duplicates
pcall(function()
	local old = PlayerGui:FindFirstChild("CactusClient")
	if old then old:Destroy() end
end)

-- =========================
-- Theme / config
-- =========================
local THEME = {
	BG = Color3.fromRGB(10, 10, 10),
	PANEL = Color3.fromRGB(14, 14, 14),
	PANEL2 = Color3.fromRGB(18, 18, 18),
	STROKE = Color3.fromRGB(0, 170, 90),
	TEXT = Color3.fromRGB(0, 255, 150),
	TEXT_DIM = Color3.fromRGB(170, 255, 210),
	BUTTON = Color3.fromRGB(18, 22, 18),
	BUTTON_HOVER = Color3.fromRGB(22, 30, 22),
	BUTTON_ACTIVE = Color3.fromRGB(0, 140, 80),
}

local CFG = {
	Title = "Cactus Client",
	StartSize = Vector2.new(520, 320),
	MinSize = Vector2.new(420, 260),
	MaxSize = Vector2.new(900, 650),
	StartPos = Vector2.new(22, 200),
	TabWidth = 110,
	TopBarHeight = 34,
	CornerGrip = 18,
}

-- =========================
-- Shared state (modules can use this)
-- =========================
local State = {
	SelectedPlayer = nil,
	Waypoint = nil,
	ESPEnabled = false,
	BotMode = "idle",
}

-- =========================
-- GUI setup
-- =========================
local gui = Instance.new("ScreenGui")
gui.Name = "CactusClient"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = PlayerGui

local window = Instance.new("Frame")
window.Name = "Window"
window.BackgroundColor3 = THEME.PANEL
window.BorderSizePixel = 0
window.Size = UDim2.fromOffset(CFG.StartSize.X, CFG.StartSize.Y)
window.Position = UDim2.fromOffset(CFG.StartPos.X, CFG.StartPos.Y)
window.Parent = gui
Instance.new("UICorner", window).CornerRadius = UDim.new(0, 12)

local stroke = Instance.new("UIStroke")
stroke.Color = THEME.STROKE
stroke.Thickness = 1
stroke.Parent = window

-- Top bar (drag handle + title + stats)
local topBar = Instance.new("Frame")
topBar.Name = "TopBar"
topBar.BackgroundColor3 = THEME.BG
topBar.BorderSizePixel = 0
topBar.Size = UDim2.new(1, 0, 0, CFG.TopBarHeight)
topBar.Parent = window
Instance.new("UICorner", topBar).CornerRadius = UDim.new(0, 12)

-- Fix rounding at bottom of top bar
local topBarMask = Instance.new("Frame")
topBarMask.BackgroundColor3 = THEME.BG
topBarMask.BorderSizePixel = 0
topBarMask.Position = UDim2.new(0, 0, 0, math.floor(CFG.TopBarHeight / 2))
topBarMask.Size = UDim2.new(1, 0, 0, math.ceil(CFG.TopBarHeight / 2))
topBarMask.Parent = topBar

local title = Instance.new("TextLabel")
title.Name = "Title"
title.BackgroundTransparency = 1
title.Position = UDim2.new(0, 12, 0, 0)
title.Size = UDim2.new(0.5, -12, 1, 0)
title.Font = Enum.Font.Code
title.TextSize = 16
title.TextXAlignment = Enum.TextXAlignment.Left
title.TextColor3 = THEME.TEXT
title.Text = CFG.Title
title.Parent = topBar

local stats = Instance.new("TextLabel")
stats.Name = "Stats"
stats.BackgroundTransparency = 1
stats.Position = UDim2.new(0.5, 0, 0, 0)
stats.Size = UDim2.new(0.5, -12, 1, 0)
stats.Font = Enum.Font.Code
stats.TextSize = 14
stats.TextXAlignment = Enum.TextXAlignment.Right
stats.TextColor3 = THEME.TEXT_DIM
stats.Text = "FPS: -- | XYZ: --, --, --"
stats.Parent = topBar

-- Body
local body = Instance.new("Frame")
body.Name = "Body"
body.BackgroundColor3 = THEME.PANEL2
body.BorderSizePixel = 0
body.Position = UDim2.new(0, 0, 0, CFG.TopBarHeight)
body.Size = UDim2.new(1, 0, 1, -CFG.TopBarHeight)
body.Parent = window

-- =========================
-- Tabs (search + scroll + alphabetical)
-- =========================

local tabs = Instance.new("Frame")
tabs.Name = "Tabs"
tabs.BackgroundColor3 = THEME.PANEL
tabs.BorderSizePixel = 0
tabs.Size = UDim2.new(0, CFG.TabWidth, 1, 0)
tabs.Parent = body

-- Search bar
local searchHolder = Instance.new("Frame")
searchHolder.Size = UDim2.new(1, -12, 0, 28)
searchHolder.Position = UDim2.new(0, 6, 0, 8)
searchHolder.BackgroundColor3 = THEME.BUTTON
searchHolder.BorderSizePixel = 0
searchHolder.Parent = tabs
Instance.new("UICorner", searchHolder).CornerRadius = UDim.new(0, 8)

local searchStroke = Instance.new("UIStroke", searchHolder)
searchStroke.Color = THEME.STROKE
searchStroke.Transparency = 0.3

local searchBox = Instance.new("TextBox")
searchBox.Size = UDim2.new(1, -10, 1, -4)
searchBox.Position = UDim2.new(0, 5, 0, 2)
searchBox.BackgroundTransparency = 1
searchBox.Text = ""
searchBox.PlaceholderText = "Search..."
searchBox.Font = Enum.Font.Code
searchBox.TextSize = 14
searchBox.TextColor3 = THEME.TEXT
searchBox.PlaceholderColor3 = THEME.TEXT_DIM
searchBox.ClearTextOnFocus = false
searchBox.Parent = searchHolder

-- Scrolling tab list
local tabScroll = Instance.new("ScrollingFrame")
tabScroll.Name = "TabScroll"
tabScroll.Position = UDim2.new(0, 0, 0, 44)
tabScroll.Size = UDim2.new(1, 0, 1, -44)
tabScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
tabScroll.ScrollBarThickness = 4
tabScroll.ScrollingDirection = Enum.ScrollingDirection.Y
tabScroll.BackgroundTransparency = 1
tabScroll.BorderSizePixel = 0
tabScroll.Parent = tabs

local tabLayout = Instance.new("UIListLayout")
tabLayout.Padding = UDim.new(0, 8)
tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
tabLayout.Parent = tabScroll

local tabPad = Instance.new("UIPadding")
tabPad.PaddingTop = UDim.new(0, 6)
tabPad.PaddingLeft = UDim.new(0, 10)
tabPad.PaddingRight = UDim.new(0, 10)
tabPad.PaddingBottom = UDim.new(0, 10)
tabPad.Parent = tabScroll

tabLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	tabScroll.CanvasSize = UDim2.new(0, 0, 0, tabLayout.AbsoluteContentSize.Y + 8)
end)

-- Pages container
local pages = Instance.new("Frame")
pages.Name = "Pages"
pages.BackgroundTransparency = 1
pages.Position = UDim2.new(0, CFG.TabWidth, 0, 0)
pages.Size = UDim2.new(1, -CFG.TabWidth, 1, 0)
pages.Parent = body

local pagesPad = Instance.new("UIPadding")
pagesPad.PaddingTop = UDim.new(0, 10)
pagesPad.PaddingLeft = UDim.new(0, 12)
pagesPad.PaddingRight = UDim.new(0, 12)
pagesPad.PaddingBottom = UDim.new(0, 12)
pagesPad.Parent = pages

-- Resize grip
local grip = Instance.new("Frame")
grip.Name = "ResizeGrip"
grip.BackgroundColor3 = THEME.BG
grip.BorderSizePixel = 0
grip.Size = UDim2.fromOffset(CFG.CornerGrip, CFG.CornerGrip)
grip.Position = UDim2.new(1, -CFG.CornerGrip - 6, 1, -CFG.CornerGrip - 6)
grip.Parent = window
Instance.new("UICorner", grip).CornerRadius = UDim.new(0, 6)

local gripIcon = Instance.new("TextLabel")
gripIcon.BackgroundTransparency = 1
gripIcon.Size = UDim2.new(1, 0, 1, 0)
gripIcon.Font = Enum.Font.Code
gripIcon.TextSize = 14
gripIcon.TextColor3 = THEME.TEXT_DIM
gripIcon.Text = "◢"
gripIcon.Parent = grip

-- =========================
-- Dragging
-- =========================
do
	local dragging = false
	local dragStartMouse
	local dragStartPos

	topBar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			dragStartMouse = input.Position
			dragStartPos = window.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)

	UIS.InputChanged:Connect(function(input)
		if not dragging then return end
		if input.UserInputType ~= Enum.UserInputType.MouseMovement then return end

		local delta = input.Position - dragStartMouse
		window.Position = UDim2.new(
			dragStartPos.X.Scale, dragStartPos.X.Offset + delta.X,
			dragStartPos.Y.Scale, dragStartPos.Y.Offset + delta.Y
		)
	end)
end

-- =========================
-- Resizing
-- =========================
do
	local resizing = false
	local resizeStartMouse
	local resizeStartSize

	grip.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			resizing = true
			resizeStartMouse = input.Position
			resizeStartSize = Vector2.new(window.AbsoluteSize.X, window.AbsoluteSize.Y)

			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					resizing = false
				end
			end)
		end
	end)

	UIS.InputChanged:Connect(function(input)
		if not resizing then return end
		if input.UserInputType ~= Enum.UserInputType.MouseMovement then return end

		local delta = input.Position - resizeStartMouse
		local newX = math.clamp(resizeStartSize.X + delta.X, CFG.MinSize.X, CFG.MaxSize.X)
		local newY = math.clamp(resizeStartSize.Y + delta.Y, CFG.MinSize.Y, CFG.MaxSize.Y)

		window.Size = UDim2.fromOffset(newX, newY)
	end)
end

-- =========================
-- Tabs + Pages
-- =========================
local PagesByName = {}
local TabButtons = {}
local CurrentPageName = nil

-- Alphabetical ordering
local function resortTabs()
	local names = {}

	for name in pairs(TabButtons) do
		table.insert(names, name)
	end

	table.sort(names, function(a, b)
		return a:lower() < b:lower()
	end)

	for i, name in ipairs(names) do
		TabButtons[name].LayoutOrder = i
	end
end

-- Search filtering
local function applySearch(text)
	text = text:lower()

	for name, btn in pairs(TabButtons) do
		btn.Visible = (text == "" or name:lower():find(text, 1, true) ~= nil)
	end
end

searchBox:GetPropertyChangedSignal("Text"):Connect(function()
	applySearch(searchBox.Text)
end)


local function makeTab(name, order)
	local btn = Instance.new("TextButton")
	btn.Name = name .. "Tab"
	btn.Size = UDim2.new(1, 0, 0, 30)
	btn.BackgroundColor3 = THEME.BUTTON
	btn.BorderSizePixel = 0
	btn.Text = name
	btn.Font = Enum.Font.Code
	btn.TextSize = 14
	btn.TextColor3 = THEME.TEXT_DIM
	btn.AutoButtonColor = false
	btn.LayoutOrder = order or 1
	btn.Parent = tabScroll
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

	btn.MouseEnter:Connect(function()
		if CurrentPageName ~= name then
			btn.BackgroundColor3 = THEME.BUTTON_HOVER
		end
	end)
	btn.MouseLeave:Connect(function()
		if CurrentPageName ~= name then
			btn.BackgroundColor3 = THEME.BUTTON
		end
	end)

	return btn
end

local function makePage(name)
	local page = Instance.new("Frame")
	page.Name = name .. "Page"
	page.BackgroundColor3 = THEME.PANEL
	page.BorderSizePixel = 0
	page.Size = UDim2.new(1, 0, 1, 0)
	page.Visible = false
        page.ClipsDescendants = false
	page.Parent = pages
	Instance.new("UICorner", page).CornerRadius = UDim.new(0, 10)

	local pageStroke = Instance.new("UIStroke")
	pageStroke.Color = Color3.fromRGB(0, 90, 55)
	pageStroke.Thickness = 1
	pageStroke.Transparency = 0.4
	pageStroke.Parent = page

	local header = Instance.new("TextLabel")
	header.BackgroundTransparency = 1
	header.Position = UDim2.new(0, 12, 0, 10)
	header.Size = UDim2.new(1, -24, 0, 22)
	header.Font = Enum.Font.Code
	header.TextSize = 16
	header.TextXAlignment = Enum.TextXAlignment.Left
	header.TextColor3 = THEME.TEXT
	header.Text = name
	header.Parent = page

	return page
end

local function setActivePage(name)
	if CurrentPageName == name then return end
	CurrentPageName = name

	for n, page in pairs(PagesByName) do
		page.Visible = (n == name)
	end

	for n, btn in pairs(TabButtons) do
		if n == name then
			btn.BackgroundColor3 = THEME.BUTTON_ACTIVE
			btn.TextColor3 = Color3.new(1, 1, 1)
		else
			btn.BackgroundColor3 = THEME.BUTTON
			btn.TextColor3 = THEME.TEXT_DIM
		end
	end
end

local function addTabAndPage(name, order)
	local btn = makeTab(name, order)
	local page = makePage(name)

	TabButtons[name] = btn
	PagesByName[name] = page

        resortTabs()

	btn.MouseButton1Click:Connect(function()
		setActivePage(name)
	end)

	return page
end

-- Create your pages
local BotPage       = addTabAndPage("Bot", 1)
local TeleportPage  = addTabAndPage("Teleport", 2)
local WaypointsPage = addTabAndPage("Waypoints", 3)
local ESPPage       = addTabAndPage("ESP", 4)
local DevPage       = addTabAndPage("Dev", 5)
local PhasePage     = addTabAndPage("Phase", 4)
local WorldScannerPage = addTabAndPage("World", 6)
local FullbrightPage = addTabAndPage("Fullbright", 6)
local FlyPage       = addTabAndPage("Fly", 6)
local FreecamPage = addTabAndPage("Freecam", 7)
local TPghostPage = addTabAndPage("TPghost", 8)
local PearlPage = addTabAndPage("Pearl", 9)

setActivePage("Bot")

-- =========================
-- Helpers for pages (basic text blocks)
-- =========================
local function addHint(page, text)
	local hint = Instance.new("TextLabel")
	hint.BackgroundTransparency = 1
	hint.Position = UDim2.new(0, 12, 0, 38)
	hint.Size = UDim2.new(1, -24, 0, 40)
	hint.Font = Enum.Font.Code
	hint.TextSize = 13
	hint.TextXAlignment = Enum.TextXAlignment.Left
	hint.TextYAlignment = Enum.TextYAlignment.Top
	hint.TextColor3 = THEME.TEXT_DIM
	hint.TextWrapped = true
	hint.Text = text
	hint.Parent = page
	return hint
end

-- =========================
-- FPS + Coords (top bar)
-- =========================
do
	local frames = 0
	local lastTick = os.clock()
	local fps = 0

	local function getHRP()
		local char = LocalPlayer.Character
		if not char then return nil end
		return char:FindFirstChild("HumanoidRootPart")
	end

	RunService.RenderStepped:Connect(function()
		frames += 1
		local now = os.clock()
		local dt = now - lastTick

		-- Update FPS once per second-ish
		if dt >= 1 then
			fps = math.floor(frames / dt + 0.5)
			frames = 0
			lastTick = now
		end

		local hrp = getHRP()
		if hrp then
			local p = hrp.Position
			stats.Text = string.format("FPS: %d | XYZ: %.1f, %.1f, %.1f", fps, p.X, p.Y, p.Z)
		else
			stats.Text = string.format("FPS: %d | XYZ: --, --, --", fps)
		end
	end)
end

print("[Cactus Client] Shell loaded (draggable + resizable + tabs + FPS/coords).")


-- =========================
-- Module loader (hosted - executor friendly)
-- =========================

local Client = {
	State = State,
	Theme = THEME,
        Modules = {},
	Player = LocalPlayer,
    Pages = {
	Bot = BotPage,
	Teleport = TeleportPage,
	Waypoints = WaypointsPage,
	ESP = ESPPage,
	Dev = DevPage,
	Phase = PhasePage,
	WorldScanner = WorldScannerPage,
	Fullbright = FullbrightPage,
	Fly = FlyPage,
	Freecam = FreecamPage,
	TPghost = TPghostPage,
	Pearl = PearlPage,
},
	Services = {
		Players = Players,
		RunService = RunService,
		UIS = UIS,
	}
}
local MODULES = {
    Waypoints = "https://raw.githubusercontent.com/NoOne20104/cactus-client/main/Modules/Waypoints.lua",
    Bot = "https://raw.githubusercontent.com/NoOne20104/cactus-client/main/Modules/Bot.lua",
    PlayerTP = "https://raw.githubusercontent.com/NoOne20104/cactus-client/main/Modules/PlayerTP.lua",
    Dev = "https://raw.githubusercontent.com/NoOne20104/cactus-client/main/Modules/Dev.lua",
    ESP = "https://raw.githubusercontent.com/NoOne20104/cactus-client/main/Modules/ESP.lua",
    Phase = "https://raw.githubusercontent.com/NoOne20104/cactus-client/main/Modules/Phase.lua",
    WorldScanner = "https://raw.githubusercontent.com/NoOne20104/cactus-client/main/Modules/WorldScanner.lua",
    Fullbright = "https://raw.githubusercontent.com/NoOne20104/cactus-client/main/Modules/Fullbright.lua",
    Fly = "https://raw.githubusercontent.com/NoOne20104/cactus-client/main/Modules/Fly.lua",
    Freecam = "https://raw.githubusercontent.com/NoOne20104/cactus-client/main/Modules/Freecam.lua",
    TPghost = "https://raw.githubusercontent.com/NoOne20104/cactus-client/main/Modules/TPghost.lua",
	Pearl = "https://raw.githubusercontent.com/NoOne20104/cactus-client/main/Modules/Pearl.lua",
    
   }

local function loadModule(name, url)
	print("[Cactus] Loading module:", name)

	local ok, src = pcall(function()
		return game:HttpGet(url)
	end)

	if not ok then
		warn("[Cactus] Failed to download:", name)
		return
	end

	local mod = loadstring(src)()

	if type(mod) == "table" and type(mod.Init) == "function" then
                Client.Modules[name] = mod
		mod.Init(Client)
		print("[Cactus] Loaded module:", name)
	else
		warn("[Cactus] Invalid module:", name)
	end
end

for name, url in pairs(MODULES) do
	task.spawn(loadModule, name, url)
end
