local Waypoints = {}

function Waypoints.Init(Client)

	print("[Waypoints] Module loading...")

	local RunService = Client.Services.RunService
	local LocalPlayer = Client.Player
	local Page = Client.Pages.Waypoints
	local State = Client.State
	local Theme = Client.Theme

	local waypointPos = nil
	local markerPart, beam, attachment0, attachment1, camConn

	-- =========================
	-- UI
	-- =========================

	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(0, 220, 0, 205)
	frame.Position = UDim2.new(0, 10, 0, 10)
	frame.BackgroundColor3 = Color3.fromRGB(14,14,14)
	frame.BorderSizePixel = 0
	frame.Parent = Page
	Instance.new("UICorner", frame).CornerRadius = UDim.new(0,10)

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

	assert(setBtn and tpBtn and walkBtn and clearBtn, "[Waypoints] Button creation failed")

	-- =========================
	-- Marker
	-- =========================

	local function createMarker(pos)
		if camConn then camConn:Disconnect() end
		if markerPart then markerPart:Destroy() end

		markerPart = Instance.new("Part")
		markerPart.Shape = Enum.PartType.Ball
		markerPart.Size = Vector3.new(0.6,0.6,0.6)
		markerPart.Material = Enum.Material.Neon
		markerPart.Color = Theme.TEXT
		markerPart.Anchored = true
		markerPart.CanCollide = false
		markerPart.Position = pos
		markerPart.Parent = workspace

		attachment0 = Instance.new("Attachment", markerPart)

		local camPart = Instance.new("Part")
		camPart.Anchored = true
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
			if workspace.CurrentCamera then
				camPart.Position = workspace.CurrentCamera.CFrame.Position
			end
		end)
	end

	-- =========================
	-- Buttons
	-- =========================

	setBtn.MouseButton1Click:Connect(function()
		local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
		if not hrp then return end

		waypointPos = hrp.Position
		State.Waypoint = waypointPos
		createMarker(waypointPos)

		print("[Waypoints] Set:", waypointPos)
	end)

	tpBtn.MouseButton1Click:Connect(function()
		if waypointPos and LocalPlayer.Character then
			local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
			if hrp then
				hrp.CFrame = CFrame.new(waypointPos + Vector3.new(0,3,0))
			end
		end
	end)

	walkBtn.MouseButton1Click:Connect(function()
		print("[Waypoints] Walk button pressed")

		if not waypointPos then
			warn("[Waypoints] No waypoint set")
			return
		end

		if Client.Modules and Client.Modules.Bot and Client.Modules.Bot.GotoPosition then
			Client.Modules.Bot.GotoPosition(waypointPos)
		else
			warn("[Waypoints] Bot.GotoPosition missing")
		end
	end)

	clearBtn.MouseButton1Click:Connect(function()
		waypointPos = nil
		State.Waypoint = nil
		if camConn then camConn:Disconnect() end
		if markerPart then markerPart:Destroy() end
	end)

	print("[Waypoints] Loaded OK")
end

return Waypoints
