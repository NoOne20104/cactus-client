-- Reactive Walker v1.4
-- Speed-first build: Goto / Follow + always-visible green path

local Bot = {}

function Bot.Init(Client)

-- =========================
-- Core
-- =========================

local Players = Client.Services.Players
local PathfindingService = game:GetService("PathfindingService")
local LOCAL_PLAYER = Client.Player

local Workspace = workspace

-- =========================
-- Config
-- =========================

local ARRIVAL_DISTANCE = 5
local STUCK_TIME = 2
local FOLLOW_REPATH_DISTANCE = 10

-- =========================
-- State
-- =========================

local humanoid, rootPart
local currentPath, waypoints, waypointIndex
local lastPos, lastMove = nil, os.clock()

local selectedTarget = nil
local mode = "idle"
local lastFollowPos = nil

-- =========================
-- 🌵 Dumb green path system
-- =========================

local PATH_COLOR = Color3.fromRGB(0,255,140)
local visuals = {}

local function clearPath()
	for _,v in ipairs(visuals) do
		pcall(function() v:Destroy() end)
	end
	table.clear(visuals)
end

local function spawnDot(pos)
	local p = Instance.new("Part")
	p.Shape = Enum.PartType.Ball
	p.Size = Vector3.new(0.4,0.4,0.4)
	p.Anchored = true
	p.CanCollide = false
	p.Material = Enum.Material.Neon
	p.Color = PATH_COLOR
	p.Position = pos
	p.Parent = Workspace
	table.insert(visuals,p)
end

local function spawnLine(a,b)
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.Material = Enum.Material.Neon
	p.Color = PATH_COLOR

	local dist = (a-b).Magnitude
	p.Size = Vector3.new(0.12,0.12,dist)
	p.CFrame = CFrame.lookAt((a+b)/2, b)
	p.Parent = Workspace

	table.insert(visuals,p)
end

local function drawPath(points)
	clearPath()
	if not points or #points < 2 then return end

	for i,pos in ipairs(points) do
		spawnDot(pos)
		if i > 1 then
			spawnLine(points[i-1], pos)
		end
	end
end

-- =========================
-- Character
-- =========================

local function getChar()
	local c = LOCAL_PLAYER.Character or LOCAL_PLAYER.CharacterAdded:Wait()
	humanoid = c:WaitForChild("Humanoid")
	rootPart = c:WaitForChild("HumanoidRootPart")
end

-- =========================
-- Bot logic
-- =========================

local function isStuck()
	if not lastPos then
		lastPos = rootPart.Position
		return false
	end

	if (rootPart.Position - lastPos).Magnitude > 0.6 then
		lastMove = os.clock()
		lastPos = rootPart.Position
		return false
	end

	return (os.clock() - lastMove) > STUCK_TIME
end

local function getTargetRoot()
	if not selectedTarget then return end
	local c = selectedTarget.Character
	return c and c:FindFirstChild("HumanoidRootPart")
end

local function computePath(goal)
	local path = PathfindingService:CreatePath()
	path:ComputeAsync(rootPart.Position, goal)

	local wps = path:GetWaypoints()
	if #wps < 2 then return false end

	currentPath = path
	waypoints = wps
	waypointIndex = 2

	local pts = {}
	for _,w in ipairs(wps) do
		table.insert(pts, w.Position)
	end

	drawPath(pts)
	return true
end

local function walk()
	if not waypoints or not waypoints[waypointIndex] then
		clearPath()
		return
	end

	local wp = waypoints[waypointIndex]

	if wp.Action == Enum.PathWaypointAction.Jump then
		humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
	end

	humanoid:MoveTo(wp.Position)
	humanoid.MoveToFinished:Once(function(ok)
		if not ok or isStuck() then
			currentPath, waypoints = nil, nil
			clearPath()
			return
		end
		waypointIndex += 1
		walk()
	end)
end

task.spawn(function()
	while true do
		task.wait(0.25)

		if mode == "idle" then continue end
		local tr = getTargetRoot()
		if not tr then continue end

		local pos = tr.Position
		local dist = (rootPart.Position - pos).Magnitude

		if mode == "goto" and dist < ARRIVAL_DISTANCE then
			mode = "idle"
			humanoid:Move(Vector3.zero)
			clearPath()
			continue
		end

		if mode == "follow" then
			if not lastFollowPos then lastFollowPos = pos end
			if (lastFollowPos - pos).Magnitude > FOLLOW_REPATH_DISTANCE then
				currentPath, waypoints = nil, nil
				lastFollowPos = pos
				clearPath()
			end
		end

		if not currentPath or not waypoints then
			if computePath(pos) then
				walk()
			end
		end
	end
end)

-- =========================
-- GUI
-- =========================

local function createGUI()
	local Page = Client.Pages.Bot
	local Theme = Client.Theme

	local ui = Instance.new("Folder")
	ui.Name = "BotUI"
	ui.Parent = Page

	local frame = Instance.new("Frame", ui)
	frame.Size = UDim2.new(0,220,0,200)
	frame.Position = UDim2.new(0,10,0,10)
	frame.BackgroundColor3 = Color3.fromRGB(14,14,14)
	frame.BorderSizePixel = 0
	Instance.new("UICorner", frame).CornerRadius = UDim.new(0,10)

	local stroke = Instance.new("UIStroke", frame)
	stroke.Color = Theme.STROKE
	stroke.Transparency = 0.4

	local title = Instance.new("TextLabel", frame)
	title.Size = UDim2.new(1,-10,0,28)
	title.Position = UDim2.new(0,10,0,4)
	title.BackgroundTransparency = 1
	title.Text = "Bot"
	title.Font = Enum.Font.Code
	title.TextSize = 16
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextColor3 = Theme.TEXT

	local function btn(text,y)
		local b = Instance.new("TextButton", frame)
		b.Size = UDim2.new(1,-20,0,30)
		b.Position = UDim2.new(0,10,0,y)
		b.BackgroundColor3 = Theme.BUTTON
		b.Text = text
		b.Font = Enum.Font.Code
		b.TextSize = 14
		b.TextColor3 = Theme.TEXT_DIM
		b.BorderSizePixel = 0
		Instance.new("UICorner", b).CornerRadius = UDim.new(0,6)
		return b
	end

	local selectBtn = btn("Select Player",36)
	local gotoBtn   = btn("Goto Target",72)
	local followBtn = btn("Follow Target",108)
	local stopBtn   = btn("Stop",144)

	local label = Instance.new("TextLabel", frame)
	label.Size = UDim2.new(1,-20,0,20)
	label.Position = UDim2.new(0,10,0,176)
	label.BackgroundTransparency = 1
	label.Text = "Target: none"
	label.Font = Enum.Font.Code
	label.TextSize = 13
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextColor3 = Theme.TEXT_DIM

	local drop = Instance.new("Frame", ui)
	drop.Visible = false
	drop.Size = UDim2.new(0,190,0,160)
	drop.BackgroundColor3 = Color3.fromRGB(14,14,14)
	drop.BorderSizePixel = 0
	Instance.new("UICorner", drop).CornerRadius = UDim.new(0,10)

	local dStroke = Instance.new("UIStroke", drop)
	dStroke.Color = Theme.STROKE
	dStroke.Transparency = 0.4

	local list = Instance.new("ScrollingFrame", drop)
	list.Size = UDim2.new(1,-10,1,-10)
	list.Position = UDim2.new(0,5,0,5)
	list.CanvasSize = UDim2.new()
	list.ScrollBarImageTransparency = 0.3
	list.BackgroundTransparency = 1
	list.BorderSizePixel = 0
	list.Active = true

	local lay = Instance.new("UIListLayout", list)
	lay.Padding = UDim.new(0,6)

	local function rebuild()
		for _,c in ipairs(list:GetChildren()) do
			if c:IsA("TextButton") then c:Destroy() end
		end

		for _,p in ipairs(Players:GetPlayers()) do
			if p ~= LOCAL_PLAYER then
				local b = Instance.new("TextButton", list)
				b.Size = UDim2.new(1,0,0,30)
				b.Text = p.Name
				b.Font = Enum.Font.Code
				b.TextSize = 14
				b.TextColor3 = Theme.TEXT_DIM
				b.BackgroundColor3 = Theme.BUTTON
				b.BorderSizePixel = 0
				Instance.new("UICorner", b).CornerRadius = UDim.new(0,6)

				b.MouseButton1Click:Connect(function()
					selectedTarget = p
					label.Text = "Target: "..p.Name
					drop.Visible = false
				end)
			end
		end

		task.wait()
		list.CanvasSize = UDim2.new(0,0,0, lay.AbsoluteContentSize.Y + 6)
	end

	selectBtn.MouseButton1Click:Connect(function()
		drop.Visible = not drop.Visible
		drop.Position = UDim2.new(0, frame.Position.X.Offset, 0, frame.Position.Y.Offset + frame.Size.Y.Offset + 6)
		rebuild()
	end)

	gotoBtn.MouseButton1Click:Connect(function()
		if selectedTarget then
			mode = "goto"
			currentPath, waypoints = nil, nil
			clearPath()
		end
	end)

	followBtn.MouseButton1Click:Connect(function()
		if selectedTarget then
			mode = "follow"
			lastFollowPos = nil
			currentPath, waypoints = nil, nil
			clearPath()
		end
	end)

	stopBtn.MouseButton1Click:Connect(function()
		mode = "idle"
		currentPath, waypoints = nil, nil
		clearPath()
		if humanoid then humanoid:Move(Vector3.zero) end
	end)
end

-- =========================
-- Boot
-- =========================

getChar()
createGUI()

LOCAL_PLAYER.CharacterAdded:Connect(function()
	task.wait(1)
	getChar()
	clearPath()
end)

end

return Bot
