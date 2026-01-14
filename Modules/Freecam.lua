local Freecam = {}

function Freecam.Init(Client)

	-- =========================
	-- Services / Core
	-- =========================

	local UIS = game:GetService("UserInputService")
	local RunService = Client.Services.RunService
	local LocalPlayer = Client.Player
	local Page = Client.Pages.Freecam
	local Theme = Client.Theme
	local Camera = workspace.CurrentCamera

	print("[Freecam] Init")

	-- =========================
	-- State
	-- =========================

	Freecam.Enabled = false

	local saved = {}
	local humanoid
	local root
	local camConn

	local yaw = 0
	local pitch = 0

	-- =========================
	-- Character
	-- =========================

	local function getChar()
		local char = LocalPlayer.Character
		if not char then return end
		humanoid = char:FindFirstChildOfClass("Humanoid")
		root = char:FindFirstChild("HumanoidRootPart")
	end

	-- =========================
	-- Core Freecam
	-- =========================

	local function startFreecam()
		if Freecam.Enabled then return end
		if not Camera then return end

		getChar()
		if not humanoid or not root then return end

		Freecam.Enabled = true

		-- save camera
		saved.Type = Camera.CameraType
		saved.Subject = Camera.CameraSubject
		saved.CFrame = Camera.CFrame
		saved.MouseBehavior = UIS.MouseBehavior
		saved.MouseIcon = UIS.MouseIconEnabled

		-- save character
		saved.WalkSpeed = humanoid.WalkSpeed
		saved.JumpPower = humanoid.JumpPower
		saved.AutoRotate = humanoid.AutoRotate

		-- freeze character
		humanoid.WalkSpeed = 0
		humanoid.JumpPower = 0
		humanoid.AutoRotate = false

		-- camera mode
		Camera.CameraType = Enum.CameraType.Scriptable
		UIS.MouseBehavior = Enum.MouseBehavior.Default
		UIS.MouseIconEnabled = true

		-- starting camera position (3rd person)
		local startCF = root.CFrame * CFrame.new(0, 2, 10)
		Camera.CFrame = startCF

		local look = startCF.LookVector
		yaw = math.atan2(-look.X, -look.Z)
		pitch = math.asin(look.Y)

		-- camera control loop
		camConn = RunService.RenderStepped:Connect(function()

			if not Freecam.Enabled then return end

			local delta = UIS:GetMouseDelta()
			yaw -= delta.X * 0.002
			pitch -= delta.Y * 0.002
			pitch = math.clamp(pitch, -1.45, 1.45)

			local rot = CFrame.fromOrientation(pitch, yaw, 0)
			Camera.CFrame = CFrame.new(Camera.CFrame.Position) * rot
		end)

		print("[Freecam] Enabled")
	end

	local function stopFreecam()
		if not Freecam.Enabled then return end
		Freecam.Enabled = false

		if camConn then camConn:Disconnect() camConn = nil end

		-- restore camera
		if Camera then
			Camera.CameraType = saved.Type
			Camera.CameraSubject = saved.Subject
			Camera.CFrame = saved.CFrame
		end

		-- restore input
		UIS.MouseBehavior = saved.MouseBehavior
		UIS.MouseIconEnabled = saved.MouseIcon

		-- restore character
		if humanoid then
			humanoid.WalkSpeed = saved.WalkSpeed
			humanoid.JumpPower = saved.JumpPower
			humanoid.AutoRotate = saved.AutoRotate
		end

		print("[Freecam] Disabled")
	end

	-- =========================
	-- GUI
	-- =========================

	for _,c in ipairs(Page:GetChildren()) do
		if c:IsA("Frame") and c.Name == "CactusFreecamFrame" then
			c:Destroy()
		end
	end

	local frame = Instance.new("Frame")
	frame.Name = "CactusFreecamFrame"
	frame.Size = UDim2.new(0,220,0,120)
	frame.Position = UDim2.new(0,10,0,10)
	frame.BackgroundColor3 = Color3.fromRGB(14,14,14)
	frame.BorderSizePixel = 0
	frame.Parent = Page
	Instance.new("UICorner", frame).CornerRadius = UDim.new(0,10)

	local stroke = Instance.new("UIStroke", frame)
	stroke.Color = Theme.STROKE
	stroke.Transparency = 0.4

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1,-12,0,26)
	title.Position = UDim2.new(0,10,0,4)
	title.BackgroundTransparency = 1
	title.Text = "Freecam"
	title.Font = Enum.Font.Code
	title.TextSize = 16
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextColor3 = Theme.TEXT
	title.Parent = frame

	local toggleBtn = Instance.new("TextButton")
	toggleBtn.Size = UDim2.new(1,-20,0,30)
	toggleBtn.Position = UDim2.new(0,10,0,44)
	toggleBtn.BackgroundColor3 = Theme.BUTTON
	toggleBtn.Text = "Freecam : OFF"
	toggleBtn.Font = Enum.Font.Code
	toggleBtn.TextSize = 14
	toggleBtn.TextColor3 = Theme.TEXT_DIM
	toggleBtn.BorderSizePixel = 0
	toggleBtn.Parent = frame
	Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0,6)

	-- =========================
	-- Button
	-- =========================

	toggleBtn.MouseButton1Click:Connect(function()
		if Freecam.Enabled then
			stopFreecam()
			toggleBtn.Text = "Freecam : OFF"
			toggleBtn.TextColor3 = Theme.TEXT_DIM
		else
			startFreecam()
			toggleBtn.Text = "Freecam : ON"
			toggleBtn.TextColor3 = Theme.TEXT
		end
	end)

	-- safety: respawn reset
	LocalPlayer.CharacterAdded:Connect(function()
		task.wait(0.2)
		if Freecam.Enabled then
			stopFreecam()
			toggleBtn.Text = "Freecam : OFF"
			toggleBtn.TextColor3 = Theme.TEXT_DIM
		end
	end)
end

return Freecam
