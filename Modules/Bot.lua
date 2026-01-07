-- Reactive Walker v1.2
-- Goto + Follow with clean GUI (Cactus Client Module)

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
		return true
	else
		currentPath = nil
		waypoints = nil
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
-- GUI (Waypoints style)
-- =========================

local function createGUI()

	local Page = Client.Pages.Bot
	local Theme = Client.Theme

	-- main panel
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

	-- title
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -10, 0, 28)
	title.Position = UDim2.new(0, 10, 0, 4)
	title.BackgroundTransparency = 1
	title.Text = "Bot"
	title.Font = Enum.Font.Code
	title.TextSize = 16
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextColor3 = Theme.TEXT
	title.Parent = frame

	-- button helper (identical style to Waypoints)
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

	local selectBtn = makeButton("Select Player", 36)
	local gotoBtn   = makeButton("Goto Target", 72)
	local followBtn = makeButton("Follow Target", 108)
	local stopBtn   = makeButton("Stop", 144)

	local selectedLabel = Instance.new("TextLabel")
	selectedLabel.Size = UDim2.new(1, -20, 0, 20)
	selectedLabel.Position = UDim2.new(0, 10, 0, 176)
	selectedLabel.BackgroundTransparency = 1
	selectedLabel.Text = "Target: none"
	selectedLabel.Font = Enum.Font.Code
	selectedLabel.TextSize = 13
	selectedLabel.TextXAlignment = Enum.TextXAlignment.Left
	selectedLabel.TextColor3 = Theme.TEXT_DIM
	selectedLabel.Parent = frame

	-- dropdown
	local dropdown = Instance.new("Frame")
	dropdown.Visible = false
	dropdown.Size = UDim2.new(0, 220, 0, 160)
	dropdown.BackgroundColor3 = Color3.fromRGB(14,14,14)
	dropdown.BorderSizePixel = 0
	dropdown.Parent = Page
	Instance.new("UICorner", dropdown).CornerRadius = UDim.new(0, 10)

	local dStroke = Instance.new("UIStroke", dropdown)
	dStroke.Color = Theme.STROKE
	dStroke.Transparency = 0.4

	local list = Instance.new("ScrollingFrame")
	list.Size = UDim2.new(1, -10, 1, -10)
	list.Position = UDim2.new(0, 5, 0, 5)
	list.CanvasSize = UDim2.new(0,0,0,0)
	list.ScrollBarImageTransparency = 0.3
	list.BackgroundTransparency = 1
	list.Parent = dropdown

	local layout = Instance.new("UIListLayout", list)
	layout.Padding = UDim.new(0,6)

	local function rebuildList()
		for _, c in ipairs(list:GetChildren()) do
			if c:IsA("TextButton") then c:Destroy() end
		end

		for _, plr in ipairs(Players:GetPlayers()) do
			if plr ~= LOCAL_PLAYER then
				local btn = Instance.new("TextButton")
				btn.Size = UDim2.new(1,0,0,30)
				btn.Text = plr.Name
				btn.Font = Enum.Font.Code
				btn.TextSize = 14
				btn.TextColor3 = Theme.TEXT_DIM
				btn.BackgroundColor3 = Theme.BUTTON
				btn.BorderSizePixel = 0
				btn.Parent = list
				Instance.new("UICorner", btn).CornerRadius = UDim.new(0,6)

				btn.MouseButton1Click:Connect(function()
					selectedTargetPlayer = plr
					selectedLabel.Text = "Target: " .. plr.Name
					dropdown.Visible = false
				end)
			end
		end

		task.wait()
		list.CanvasSize = UDim2.new(0,0,0, layout.AbsoluteContentSize.Y + 6)
	end

	local function openDropdown(btn)
		dropdown.Visible = not dropdown.Visible
		local pos = btn.AbsolutePosition
		local size = btn.AbsoluteSize
		dropdown.Position = UDim2.fromOffset(pos.X, pos.Y + size.Y + 6)
		rebuildList()
	end

	-- wiring (unchanged logic)
	selectBtn.MouseButton1Click:Connect(function()
		openDropdown(selectBtn)
	end)

	gotoBtn.MouseButton1Click:Connect(function()
		if selectedTargetPlayer then
			currentMode = "goto"
			currentPath = nil
			waypoints = nil
		end
	end)

	followBtn.MouseButton1Click:Connect(function()
		if selectedTargetPlayer then
			currentMode = "follow"
			lastFollowTargetPos = nil
			currentPath = nil
			waypoints = nil
		end
	end)

	stopBtn.MouseButton1Click:Connect(function()
		currentMode = "idle"
		currentPath = nil
		waypoints = nil
		if humanoid then
			humanoid:Move(Vector3.zero)
		end
	end)
end


-- =========================
-- Boot
-- =========================

getCharacter()
createGUI()
task.spawn(mainLoop)

LOCAL_PLAYER.CharacterAdded:Connect(function()
	task.wait(1)
	getCharacter()
end)

end

return Bot
