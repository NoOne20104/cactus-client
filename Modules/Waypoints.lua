local Waypoints = {}

function Waypoints.Init(Client)
	local Players = Client.Services.Players
	local RunService = Client.Services.RunService
	local LocalPlayer = Client.Player
	local Page = Client.Pages.Waypoints
	local State = Client.State
	local Theme = Client.Theme

	local waypointPos = nil
	local markerPart = nil
	local beam = nil
	local attachment0 = nil
	local attachment1 = nil
	local camConn = nil

	-- =========================
	-- UI
	-- =========================

	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(0, 220, 0, 200) -- increased for new button
	frame.Position = UDim2.new(0, 10, 0, 10)
	frame.BackgroundColor3 = Color3.fromRGB(14,14,14)
	frame.BorderSizePixel = 0
	frame.Parent = Page
	Instance.new("UICorner", frame).CornerRadius = UDim.new(0,10)

	local stroke = Instance.new("UIStroke", frame)
	stroke.Color = Theme.STROKE
	stroke.Transparency = 0.4

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1,0,0,30)
	title.BackgroundTransparency = 1
	title.Text = "Waypoints"
	title.Font = Enum.Font.Code
	title.TextSize = 16
	title.TextColor3 = Theme.TEXT
	title.Parent = frame

	local function makeButton(text, y)
		local b = Instance.new("TextButton")
		b.Size = UDim2.new(1,-20,0,30)
		b.Position = UDim2.new(0,10,0,y)
		b.BackgroundColor3 = Theme.BUTTON
		b.Text = text
		b.Font = Enum.Font.Code
		b.TextSize = 14
		b.TextColor3 = Theme.TEXT_DIM
		b.BorderSizePixel = 0
		b.Parent = frame
		Instance.new("UICorner", b).CornerRadius = UDim.new(0,6)
		return b
	end

	local setBtn   = makeButton("Set Waypoint", 40)
	local tpBtn    = makeButton("Teleport to Waypoint", 75)
	local walkBtn  = makeButton("Walk to Waypoint", 110)
	local clearBtn = makeButton("Clear Waypoint", 145)

	-- =========================
	-- Marker
	-- =========================

	local function createMarker(pos)
		if camConn then camConn:Disconnect() camConn = nil end
		if markerPart then markerPart:Destroy() end
		if beam then beam:Destroy() end

		markerPart = Instance.new("Part")
		markerPart.Size = Vector3.new(0.6,0.6,0.6)
		markerPart.Shape = Enum.PartType.Ball
		markerPart.Material = Enum.Material.Neon
		markerPart.Color = Theme.TEXT
		markerPart.Anchored = true
		markerPart.CanCollide = false
		markerPart.Position = pos
		markerPart.Parent = workspace

		local highlight = Instance.new("Highlight")
		highlight.Adornee = markerPart
		highlight.FillColor = Theme.TEXT
		highlight.OutlineColor = Theme.TEXT
		highlight.FillTransparency = 0.4
		highlight.OutlineTransparency = 0
		highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		highlight.Parent = markerPart

		attachment0 = Instance.new("Attachment", markerPart)

		local camPart = Instance.new("Part")
		camPart.Anchored = true
		camPart.CanCollide = false
		camPart.Transparency = 1
		camPart.Parent = workspace

		attachment1 = Instance.new("Attachment", camPart)

		beam = Instance.new("Beam")
		beam.Attachment0 = attachment0
		beam.Attachment1 = attachment1
		beam.Width0 = 0.1
		beam.Width1 = 0.1
		beam.Color = ColorSequence.new(Theme.TEXT)
		beam.FaceCamera = true
		beam.Parent = markerPart

		camConn = RunService.RenderStepped:Connect(function()
			if camPart and workspace.CurrentCamera then
				camPart.Position = workspace.CurrentCamera.CFrame.Position
			end
		end)
	end

	-- =========================
	-- Buttons
	-- =========================

	setBtn.MouseButton1Click:Connect(function()
		local char = LocalPlayer.Character
		if not char then return end
		local hrp = char:FindFirstChild("HumanoidRootPart")
		if not hrp then return end

		waypointPos = hrp.Position
		State.Waypoint = waypointPos
		createMarker(waypointPos)
	end)

	tpBtn.MouseButton1Click:Connect(function()
		if not waypointPos then return end
		local char = LocalPlayer.Character
		if not char then return end
		local hrp = char:FindFirstChild("HumanoidRootPart")
		if not hrp then return end

		hrp.CFrame = CFrame.new(waypointPos + Vector3.new(0,3,0))
	end)

	-- NEW: walk via Bot
	walkBtn.MouseButton1Click:Connect(function()
		if not waypointPos then return end
		if not Client.Modules then return end
		if not Client.Modules.Bot then return end

		Client.Modules.Bot:GotoPosition(waypointPos)
	end)

	clearBtn.MouseButton1Click:Connect(function()
		waypointPos = nil
		State.Waypoint = nil
		if camConn then camConn:Disconnect() camConn = nil end
		if markerPart then markerPart:Destroy() markerPart = nil end
		if beam then beam:Destroy() beam = nil end
	end)
end

return Waypoints
