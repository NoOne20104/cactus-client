-- Reactive Walker v1.2 (Cactus)
-- Goto + Follow with clean GUI (Cactus Client Module)
-- + Thin smooth cactus-green path (hard forced, no flashing)

local Bot = {}

function Bot.Init(Client)

local Players = Client.Services.Players
local PathfindingService = game:GetService("PathfindingService")
local LOCAL_PLAYER = Client.Player

local ARRIVAL_DISTANCE = 5
local STUCK_TIME = 2
local FOLLOW_REPATH_DISTANCE = 10

local humanoid
local rootPart

local currentPath
local waypoints
local waypointIndex = 1
local moving = false

local lastPosition
local lastMoveTime = os.clock()

-- target + mode
local selectedTargetPlayer = nil
local currentMode = "idle" -- "idle", "goto", "follow"
local lastFollowTargetPos = nil

print("[Cactus Bot] Loaded")

-- =========================
-- 🌵 Path visual system
-- =========================

local PATH_COLOR = Color3.fromRGB(0,255,90) -- cactus green (no blue)
local PATH_RADIUS = 0.06
local PATH_LIFT = 0.18
local PATH_NODE_SIZE = 0.18

local pathFolder = workspace:FindFirstChild("CactusBotPath")
if pathFolder then pcall(function() pathFolder:Destroy() end) end
pathFolder = Instance.new("Folder")
pathFolder.Name = "CactusBotPath"
pathFolder.Parent = workspace

local pathParts = {}
local lastSig = ""

local function destroyParts(parts)
	for _, p in ipairs(parts) do
		pcall(function() p:Destroy() end)
	end
end

local function clearPathVisual()
	destroyParts(pathParts)
	table.clear(pathParts)
	lastSig = ""
end

local function sigFromPoints(points)
	local out = {}
	for i = 1, math.min(#points, 10) do
		local v = points[i]
		out[#out+1] = string.format("%d,%d,%d",
			math.floor(v.X+0.5),
			math.floor(v.Y+0.5),
			math.floor(v.Z+0.5)
		)
	end
	return table.concat(out, ";")
end

local function applyHighlight(part)
	local h = Instance.new("Highlight")
	h.FillColor = PATH_COLOR
	h.OutlineTransparency = 1
	h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	h.Parent = part
end

local function makeNode(pos, parent)
	local p = Instance.new("Part")
	p.Shape = Enum.PartType.Ball
	p.Size = Vector3.new(PATH_NODE_SIZE,PATH_NODE_SIZE,PATH_NODE_SIZE)
	p.Anchored = true
	p.CanCollide = false
	p.Material = Enum.Material.SmoothPlastic
	p.Color = PATH_COLOR
	p.Position = pos + Vector3.new(0,PATH_LIFT,0)
	p.Parent = parent
	applyHighlight(p)
	return p
end

local function makeCylinder(a, b, parent)
	local dist = (a-b).Magnitude
	if dist < 0.05 then return nil end

	local mid = (a+b)/2 + Vector3.new(0,PATH_LIFT,0)

	local p = Instance.new("Part")
	p.Shape = Enum.PartType.Cylinder
	p.Anchored = true
	p.CanCollide = false
	p.Material = Enum.Material.SmoothPlastic
	p.Color = PATH_COLOR
	p.Size = Vector3.new(PATH_RADIUS*2, dist, PATH_RADIUS*2)
	p.CFrame = CFrame.lookAt(mid, b + Vector3.new(0,PATH_LIFT,0)) * CFrame.Angles(math.rad(90),0,0)
	p.Parent = parent
	applyHighlight(p)
	return p
end

local function drawPathSmooth(points)
	if not points or #points < 2 then return end

	local sig = sigFromPoints(points)
	if sig == lastSig then return end
	lastSig = sig

	local newParts = {}
	local temp = Instance.new("Folder", pathFolder)

	for i = 1, #points do
		newParts[#newParts+1] = makeNode(points[i], temp)
		if i > 1 then
			local seg = makeCylinder(points[i-1], points[i], temp)
			if seg then newParts[#newParts+1] = seg end
		end
	end

	destroyParts(pathParts)
	table.clear(pathParts)

	for _, p in ipairs(newParts) do
		pathParts[#pathParts+1] = p
	end

	for _, c in ipairs(temp:GetChildren()) do
		c.Parent = pathFolder
	end
	temp:Destroy()
end

-- =========================
-- Character handling
-- =========================

local function getCharacter()
	local character = LOCAL_PLAYER.Character or LOCAL_PLAYER.CharacterAdded:Wait()
	humanoid = character:WaitForChild("Humanoid")
	rootPart = character:WaitForChild("HumanoidRootPart")
end

-- =========================
-- Target handling
-- =========================

local function getTargetRoot()
	if not selectedTargetPlayer then return end
	local char = selectedTargetPlayer.Character
	if not char then return end
	return char:FindFirstChild("HumanoidRootPart")
end

-- =========================
-- Path system (logic unchanged)
-- =========================

local function computePath(targetPosition)
	local path = PathfindingService:CreatePath({
		AgentRadius = 2,
		AgentHeight = 5,
		AgentCanJump = true,
		AgentCanClimb = true,
		WaypointSpacing = 3
	})

	path:ComputeAsync(rootPart.Position, targetPosition)

	local wps = path:GetWaypoints()
	local pts = {}

	if #wps >= 2 then
		for _, wp in ipairs(wps) do
			pts[#pts+1] = wp.Position
		end
	else
		pts[1] = rootPart.Position
		pts[2] = targetPosition
	end

	drawPathSmooth(pts)

	if path.Status == Enum.PathStatus.Success then
		currentPath = path
		waypoints = wps
		waypointIndex = 2
		return true
	else
		currentPath = nil
		waypoints = nil
		return false
	end
end

-- =========================
-- Stuck detection (unchanged)
-- =========================

local function isStuck()
	if not lastPosition then
		lastPosition = rootPart.Position
		return false
	end

	local moved = (rootPart.Position - lastPosition).Magnitude

	if moved > 0.6 then
		lastMoveTime = os.clock()
		lastPosition = rootPart.Position
		return false
	end

	if os.clock() - lastMoveTime > STUCK_TIME then
		return true
	end

	return false
end

-- =========================
-- Waypoint walker (unchanged)
-- =========================

local function walkNextWaypoint()
	if not waypoints or not waypoints[waypointIndex] then
		moving = false
		return
	end

	local wp = waypoints[waypointIndex]

	if wp.Action == Enum.PathWaypointAction.Jump then
		humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
	end

	moving = true
	humanoid:MoveTo(wp.Position)

	humanoid.MoveToFinished:Once(function(reached)
		if isStuck() or not reached then
			currentPath = nil
			waypoints = nil
			moving = false
			clearPathVisual()
			return
		end

		waypointIndex += 1
		walkNextWaypoint()
	end)
end

-- =========================
-- Main loop (unchanged)
-- =========================

local function mainLoop()
	while true do
		task.wait(0.3)

		local targetRoot = getTargetRoot()
		if not targetRoot or currentMode == "idle" then continue end

		local targetPos = targetRoot.Position
		local dist = (rootPart.Position - targetPos).Magnitude

		if currentMode == "goto" then
			if dist < ARRIVAL_DISTANCE then
				humanoid:Move(Vector3.zero)
				currentMode = "idle"
				clearPathVisual()
				continue
			end
		end

		if currentMode == "follow" then
			if not lastFollowTargetPos then
				lastFollowTargetPos = targetPos
			end

			if (lastFollowTargetPos - targetPos).Magnitude > FOLLOW_REPATH_DISTANCE then
				currentPath = nil
				waypoints = nil
				lastFollowTargetPos = targetPos
			end
		end

		if not currentPath or not waypoints then
			if computePath(targetPos) then
				walkNextWaypoint()
			end
		end
	end
end

-- =========================
-- GUI (unchanged)
-- =========================
-- ⚠️ paste your GUI block here unchanged
-- =========================

-- =========================
-- Boot
-- =========================

getCharacter()
createGUI()
task.spawn(mainLoop)

LOCAL_PLAYER.CharacterAdded:Connect(function()
	task.wait(1)
	getCharacter()
	clearPathVisual()
end)

end

return Bot

