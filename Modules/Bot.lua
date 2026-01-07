-- Reactive Walker v1.2
-- Goto + Follow with clean GUI

local Players = game:GetService("Players")
local PathfindingService = game:GetService("PathfindingService")
local UIS = game:GetService("UserInputService")

local LOCAL_PLAYER = Players.LocalPlayer

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

print("[Walker] Script loaded")

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
-- GUI
-- =========================

local function createGUI()
    local gui = Instance.new("ScreenGui")
    gui.Name = "WalkerGUI"
    gui.ResetOnSpawn = false
    gui.Parent = LOCAL_PLAYER:WaitForChild("PlayerGui")

    local frame = Instance.new("Frame", gui)
    frame.Size = UDim2.fromScale(0.2, 0.18)
    frame.Position = UDim2.fromScale(0.03, 0.35)
    frame.BackgroundColor3 = Color3.fromRGB(22, 24, 35)
    frame.BorderSizePixel = 0
    Instance.new("UICorner", frame)
    local stroke = Instance.new("UIStroke", frame)
    stroke.Color = Color3.fromRGB(80, 120, 255)

    local function makeButton(text, y, color)
        local btn = Instance.new("TextButton", frame)
        btn.Size = UDim2.fromScale(0.9, 0.28)
        btn.Position = UDim2.fromScale(0.05, y)
        btn.Text = text
        btn.Font = Enum.Font.GothamBold
        btn.TextScaled = true
        btn.TextColor3 = Color3.new(1,1,1)
        btn.BackgroundColor3 = color
        btn.BorderSizePixel = 0
        Instance.new("UICorner", btn)
        return btn
    end

   local selectBtn = makeButton("SELECT PLAYER", 0.05, Color3.fromRGB(70,180,90))
local gotoBtn   = makeButton("GOTO",          0.30, Color3.fromRGB(70,110,255))
local followBtn = makeButton("FOLLOW",        0.55, Color3.fromRGB(120,90,255))
local stopBtn   = makeButton("STOP",          0.80, Color3.fromRGB(180,70,70))

    local selectedLabel = Instance.new("TextLabel", frame)
    selectedLabel.Size = UDim2.fromScale(1, 0.22)
    selectedLabel.Position = UDim2.fromScale(0, 0.72)
    selectedLabel.Text = "Target: none"
    selectedLabel.TextScaled = true
    selectedLabel.Font = Enum.Font.Gotham
    selectedLabel.TextColor3 = Color3.fromRGB(200,200,200)
    selectedLabel.BackgroundTransparency = 1

    local dropdown = Instance.new("Frame", gui)
    dropdown.Visible = false
    dropdown.Size = UDim2.fromScale(0.22, 0.32)
    dropdown.BackgroundColor3 = Color3.fromRGB(18,18,28)
    dropdown.BorderSizePixel = 0
    Instance.new("UICorner", dropdown)
    local dropStroke = Instance.new("UIStroke", dropdown)
    dropStroke.Color = Color3.fromRGB(80,120,255)

    local list = Instance.new("ScrollingFrame", dropdown)
    list.Size = UDim2.fromScale(1,1)
    list.CanvasSize = UDim2.new(0,0,0,0)
    list.ScrollBarImageTransparency = 0.3
    list.BackgroundTransparency = 1

    local layout = Instance.new("UIListLayout", list)
    layout.Padding = UDim.new(0,6)

    local function rebuildList()
        for _, c in ipairs(list:GetChildren()) do
            if c:IsA("TextButton") then c:Destroy() end
        end

        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LOCAL_PLAYER then
                local btn = Instance.new("TextButton", list)
                btn.Size = UDim2.new(1, -10, 0, 34)
                btn.Text = plr.Name
                btn.Font = Enum.Font.Gotham
                btn.TextScaled = true
                btn.TextColor3 = Color3.fromRGB(230,230,230)
                btn.BackgroundColor3 = Color3.fromRGB(30,30,45)
                btn.BorderSizePixel = 0
                Instance.new("UICorner", btn)

                btn.MouseButton1Click:Connect(function()
                    selectedTargetPlayer = plr
                    selectedLabel.Text = "Target: " .. plr.Name
                    dropdown.Visible = false
                end)
            end
        end

        task.wait()
        list.CanvasSize = UDim2.new(0,0,0, layout.AbsoluteContentSize.Y + 10)
    end

    local function openDropdown(btn)
        dropdown.Visible = not dropdown.Visible
        local pos = btn.AbsolutePosition
        local size = btn.AbsoluteSize
        dropdown.Position = UDim2.fromOffset(pos.X, pos.Y + size.Y + 6)
        rebuildList()
    end

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
	humanoid:Move(Vector3.zero)
end)
