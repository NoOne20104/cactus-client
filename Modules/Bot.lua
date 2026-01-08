-- Reactive Walker v1.2 (Path Visual Rewrite)
-- Goto + Follow with clean GUI (Cactus Client Module)
-- + Smooth neon green path visualiser

local Bot = {}

function Bot.Init(Client)

	-- =========================
	-- SAFE BOOT (prevents module crash)
	-- =========================

	if not Client then return end
	if not Client.Services then return end
	if not Client.Pages then return end

	local Players = Client.Services.Players or game:GetService("Players")
	local PathfindingService = game:GetService("PathfindingService")
	local LOCAL_PLAYER = Client.Player or Players.LocalPlayer

	-- wait for page to actually exist
	local Page = Client.Pages.Bot
	while not Page do
		task.wait()
		Page = Client.Pages.Bot
	end

	local Theme = Client.Theme or {
		STROKE = Color3.fromRGB(0,255,90),
		TEXT = Color3.fromRGB(0,255,90),
		TEXT_DIM = Color3.fromRGB(120,255,170),
		BUTTON = Color3.fromRGB(15,25,18)
	}

	-- =========================
	-- Settings
	-- =========================

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

	function Bot.GotoPosition(pos)

		if pos == nil then
			selectedTargetPosition = nil
			currentMode = "idle"
			currentPath = nil
			waypoints = nil
			clearPathVisual()
			if humanoid then
				humanoid:Move(Vector3.zero)
			end
			return
		end

		if typeof(pos) ~= "Vector3" then return end

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

			local att = Instance.new("Attachment", holder)

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
				if hrp then
					return hrp.Position
				end
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
			drawPathVisual(waypoints)
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

	task.spawn(function()
		while true do
			task.wait(0.3)

			if not rootPart then continue end

			local targetPos = getTargetPosition()
			if not targetPos or currentMode == "idle" then continue end

			local dist = (rootPart.Position - targetPos).Magnitude

			if currentMode == "goto" and dist < ARRIVAL_DISTANCE then
				humanoid:Move(Vector3.zero)
				currentMode = "idle"
				clearPathVisual()
				continue
			end

			if currentMode == "follow" then
				if not lastFollowTargetPos then
					lastFollowTargetPos = targetPos
				end

				if (lastFollowTargetPos - targetPos).Magnitude > FOLLOW_REPATH_DISTANCE then
					currentPath = nil
					waypoints = nil
					clearPathVisual()
					lastFollowTargetPos = targetPos
				end
			end

			if not currentPath or not waypoints then
				if computePath(targetPos) then
					walkNextWaypoint()
				end
			end
		end
	end)

	-- =========================
	-- GUI
	-- =========================

	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(0, 220, 0, 200)
	frame.Position = UDim2.new(0, 10, 0, 10)
	frame.BackgroundColor3 = Color3.fromRGB(14,14,14)
	frame.BorderSizePixel = 0
	frame.Parent = Page
	Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)

	local stroke = Instance.new("UIStroke", frame)
	stroke.Color = Theme.STROKE
	stroke.Transparency = 0.4

	local title = Instance.new("TextLabel", frame)
	title.Size = UDim2.new(1, -10, 0, 28)
	title.Position = UDim2.new(0, 10, 0, 4)
	title.BackgroundTransparency = 1
	title.Text = "Bot"
	title.Font = Enum.Font.Code
	title.TextSize = 16
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextColor3 = Theme.TEXT

	local function makeButton(text, y)
		local b = Instance.new("TextButton")
		b.Size = UDim2.new(1, -20, 0, 30)
		b.Position = UDim2.new(0, 10, 0, y)
		b.BackgroundColor3 = Theme.BUTTON
		b.Text = text
		b.Font = Enum.Font.Code
		b.TextSize = 14
		b.TextColor3 = Theme.TEXT_DIM
		b.BorderSizePixel = 0
		b.Parent = frame
		Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
		return b
	end

	makeButton("Select Player", 36)
	makeButton("Goto Target", 72)
	makeButton("Follow Target", 108)
	makeButton("Stop", 144)

	-- =========================
	-- Boot
	-- =========================

	getCharacter()

	LOCAL_PLAYER.CharacterAdded:Connect(function()
		task.wait(1)
		getCharacter()
	end)

end

return Bot
