-- Reactive Walker v1.5
-- Goto / Follow bot
-- HARD DEBUG BUILD: forces visible neon green path

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
local FOLLOW_REPATH_DISTANCE = 10

-- =========================
-- State
-- =========================

local humanoid, rootPart
local currentPath, waypoints, waypointIndex

local selectedTarget = nil
local mode = "idle"
local lastFollowPos = nil

-- =========================
-- 🌵 FORCED GREEN SYSTEM
-- =========================

local GREEN = Color3.fromRGB(0,255,140)
local visuals = {}

local function clearGreen()
	for _,v in ipairs(visuals) do
		pcall(function() v:Destroy() end)
	end
	table.clear(visuals)
end

local function makePart(size)
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.Material = Enum.Material.Neon
	p.Color = GREEN
	p.Size = size
	p.Parent = Workspace
	return p
end

local function drawPoint(pos)
	local p = makePart(Vector3.new(1,1,1))
	p.Position = pos + Vector3.new(0,3,0) -- lift above ground
	table.insert(visuals,p)
end

local function drawLine(a,b)
	local mid = (a+b)/2 + Vector3.new(0,3,0)
	local dist = (a-b).Magnitude
	local p = makePart(Vector3.new(0.4,0.4,dist))
	p.CFrame = CFrame.lookAt(mid, b + Vector3.new(0,3,0))
	table.insert(visuals,p)
end

local function drawPath(points)
	clearGreen()
	if not points or #points < 2 then return end

	for i,pos in ipairs(points) do
		drawPoint(pos)
		if i > 1 then
			drawLine(points[i-1], pos)
		end
	end
end

-- =========================
-- 🌵 BOOT TEST (IMPOSSIBLE TO MISS)
-- =========================

local function spawnGreenTest()
	for i = 1, 8 do
		local p = makePart(Vector3.new(2,2,2))
		p.Position = workspace.CurrentCamera.CFrame.Position + workspace.CurrentCamera.CFrame.LookVector * (i*5)
		table.insert(visuals,p)
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
-- Path logic
-- =========================

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
		clearGreen()
		return
	end

	local wp = waypoints[waypointIndex]

	if wp.Action == Enum.PathWaypointAction.Jump then
		humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
	end

	humanoid:MoveTo(wp.Position)
	humanoid.MoveToFinished:Once(function()
		waypointIndex += 1
		walk()
	end)
end

task.spawn(function()
	while true do
		task.wait(0.3)

		if mode == "idle" then continue end
		local tr = getTargetRoot()
		if not tr then continue end

		local pos = tr.Position
		local dist = (rootPart.Position - pos).Magnitude

		if mode == "goto" and dist < ARRIVAL_DISTANCE then
			mode = "idle"
			clearGreen()
			continue
		end

		if mode == "follow" then
			if not lastFollowPos then lastFollowPos = pos end
			if (lastFollowPos - pos).Magnitude > FOLLOW_REPATH_DISTANCE then
				currentPath, waypoints = nil, nil
				lastFollowPos = pos
				clearGreen()
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
-- GUI (unchanged cactus style)
-- =========================

local function createGUI()
	local Page = Client.Pages.Bot
	local Theme = Client.Theme

	local ui = Instance.new("Folder", Page)
	ui.Name = "BotUI"

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

	local function btn(t,y)
		local b = Instance.new("TextButton", frame)
		b.Size = UDim2.new(1,-20,0,30)
		b.Position = UDim2.new(0,10,0,y)
		b.BackgroundColor3 = Theme.BUTTON
		b.Text = t
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
			clearGreen()
		end
	end)

	followBtn.MouseButton1Click:Connect(function()
		if selectedTarget then
			mode = "follow"
			lastFollowPos = nil
			currentPath, waypoints = nil, nil
			clearGreen()
		end
	end)

	stopBtn.MouseButton1Click:Connect(function()
		mode = "idle"
		currentPath, waypoints = nil, nil
		clearGreen()
	end)
end

-- =========================
-- Boot
-- =========================

getChar()
createGUI()

spawnGreenTest() -- 🌵 YOU SHOULD SEE GREEN CUBES IN FRONT OF YOU

LOCAL_PLAYER.CharacterAdded:Connect(function()
	task.wait(1)
	getChar()
	clearGreen()
	spawnGreenTest()
end)

end

return Bot

