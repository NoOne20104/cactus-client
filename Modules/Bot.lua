-- Reactive Walker v1.2
-- Goto + Follow with clean GUI (Cactus Client Module)
-- + Neon green path visualiser (persistent)

local Bot = {}

function Bot.Init(Client)

local Players = Client.Services.Players
local PathfindingService = game:GetService("PathfindingService")
local Workspace = Client.Services.Workspace
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
local currentMode = "idle"
local lastFollowTargetPos = nil

print("[Cactus Bot] Loaded")

-- =========================
-- Path visual system
-- =========================

local PATH_COLOR = Color3.fromRGB(0,255,140)
local pathParts = {}

local function clearPathVisual()
	for _,p in ipairs(pathParts) do
		pcall(function() p:Destroy() end)
	end
	table.clear(pathParts)
end

local function newNode()
	local p = Instance.new("Part")
	p.Shape = Enum.PartType.Ball
	p.Size = Vector3.new(0.35,0.35,0.35)
	p.Anchored = true
	p.CanCollide = false
	p.Material = Enum.Material.Neon
	p.Color = PATH_COLOR
	p.Parent = Workspace
	return p
end

local function newLine()
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.Material = Enum.Material.Neon
	p.Color = PATH_COLOR
	p.Size = Vector3.new(0.12,0.12,1)
	p.Parent = Workspace
	return p
end

local function drawPath(path)
	clearPathVisual()
	if not path or #path < 2 then return end

	for i = 1, #path do
		local n = newNode()
		n.Position = path[i]
		table.insert(pathParts, n)
	end

	for i = 1, #path-1 do
		local a = path[i]
		local b = path[i+1]
		local dist = (a - b).Magnitude
		local mid = (a + b)/2

		local l = newLine()
		l.Size = Vector3.new(0.12,0.12,dist)
		l.CFrame = CFrame.lookAt(mid, b)
		table.insert(pathParts, l)
	end
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
-- Path system
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

	if path.Status == Enum.PathStatus.Success then
		currentPath = path
		waypoints = path:GetWaypoints()
		waypointIndex = 2

		local vis = {}
		for _, wp in ipairs(waypoints) do
			table.insert(vis, wp.Position)
		end

		drawPath(vis) -- 🌵 draw once, persist

		return true
	else
		currentPath = nil
		waypoints = nil
		clearPathVisual()
		return false
	end
end

-- =========================
-- Stuck detection
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
-- Waypoint walker
-- =========================

local function walkNextWaypoint()
	if not waypoints or not waypoints[waypointIndex] then
		moving = false
		clearPathVisual()
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
-- Main loop
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
				clearPathVisual()
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
-- (your entire GUI section stays exactly the same)
