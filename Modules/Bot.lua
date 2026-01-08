-- Reactive Walker v1.2 (Path Visual Rewrite)
-- Goto + Follow with clean GUI (Cactus Client Module)
-- + Smooth neon green path visualiser

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
local selectedTargetPosition = nil
local currentMode = "idle"
local lastFollowTargetPos = nil

print("[Cactus Bot] Loaded")

-- =========================
-- Path visuals
-- =========================

local pathFolder = Instance.new("Folder")
pathFolder.Name = "Cactus_Path"
pathFolder.Parent = workspace

local GREEN = Color3.fromRGB(0,255,90)

local function clearPathVisual()
	for _,v in ipairs(pathFolder:GetChildren()) do
		v:Destroy()
	end
end

-- 🔥 EXTERNAL API (WAYPOINTS CALL THIS)
function Bot.GotoPosition(pos)
	print("[Bot] GotoPosition called:", pos)

	if typeof(pos) ~= "Vector3" then
		warn("[Bot] Invalid position passed")
		return
	end

	selectedTargetPlayer = nil
	selectedTargetPosition = pos
	currentMode = "goto"
	currentPath = nil
	waypoints = nil
	clearPathVisual()
end

local function drawPathVisual(points)
	clearPathVisual()
	if not points or #points < 2 then return end

	local lastAttachment

	for _,wp in ipairs(points) do
		local holder = Instance.new("Part")
		holder.Size = Vector3.new(0.2,0.2,0.2)
		holder.Transparency = 1
		holder.Anchored = true
		holder.CanCollide = false
		holder.Position = wp.Position
		holder.Parent = pathFolder

		local att = Instance.new("Attachment")
		att.Parent = holder

		if lastAttachment then
			local beam = Instance.new("Beam")
			beam.Attachment0 = lastAttachment
			beam.Attachment1 = att
			beam.FaceCamera = true
			beam.Width0 = 0.18
			beam.Width1 = 0.18
			beam.LightEmission = 1
			beam.LightInfluence = 0
			beam.Color = ColorSequence.new(GREEN)
			beam.Transparency = NumberSequence.new(0)
			beam.Parent = holder
		end

		lastAttachment = att
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

local function getTargetPosition()
	if selectedTargetPlayer then
		local char = selectedTargetPlayer.Character
		if char then
			local hrp = char:FindFirstChild("HumanoidRootPart")
			if hrp then return hrp.Position end
		end
	end

	if selectedTargetPosition then
		return selectedTargetPosition
	end
end

-- =========================
-- Path system
-- =========================

local function computePath(targetPosition)
	print("[Bot] Computing path to:", targetPosition)

	clearPathVisual()

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

		print("[Bot] Path success. Waypoints:", #waypoints)
		drawPathVisual(waypoints)
		return true
	else
		warn("[Bot] Path failed:", path.Status.Name)
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
		warn("[Bot] Stuck detected")
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
		print("[Bot] Finished path")
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
			warn("[Bot] Move failed")
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

		local targetPos = getTargetPosition()
		if not targetPos or currentMode == "idle" then continue end

		if not currentPath or not waypoints then
			if computePath(targetPos) then
				walkNextWaypoint()
			end
		end
	end
end

-- =========================
-- Boot
-- =========================

getCharacter()
task.spawn(mainLoop)

LOCAL_PLAYER.CharacterAdded:Connect(function()
	task.wait(1)
	getCharacter()
end)

end

return Bot


