local Freecam = {}

function Freecam.Init(Client)

	-- =========================
	-- Services
	-- =========================

	local UIS = game:GetService("UserInputService")
	local RunService = game:GetService("RunService")
	local Players = game:GetService("Players")

	local LocalPlayer = Players.LocalPlayer
	local Camera = workspace.CurrentCamera
	local Page = Client.Pages.Freecam
	local Theme = Client.Theme

	-- =========================
	-- State
	-- =========================

	local enabled = false
	local camConn

	local humanoid
	local root

	local yaw = 0
	local pitch = 0

	local saved = {}

	-- =========================
	-- Character
	-- =========================

	local function getCharacter()
		local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
		humanoid = char:WaitForChild("Humanoid")
		root = char:WaitForChild("HumanoidRootPart")
	end

	-- =========================
	-- Freecam Core
	-- =========================

	local function enableFreecam()
		if enabled then return end
		enabled = true

		getCharacter()

		-- save camera
		saved.CameraType = Camera.CameraType
		saved.CameraSubject = Camera.CameraSubject
		saved.CameraCFrame = Camera.CFrame

		-- save humanoid
		saved.WalkSpeed = humanoid.WalkSpeed
		saved.JumpPower = humanoid.JumpPower
		saved.AutoRotate = humanoid.AutoRotate

		-- freeze player
		humanoid.WalkSpeed = 0
		humanoid.JumpPower = 0
		humanoid.AutoRotate = false

		-- camera setup
		Camera.CameraType = Enum.CameraType.Scriptable

		-- start behind player
		local startCF = root.CFrame * CFrame.new(0, 2, 10)
		Camera.CFrame = startCF

		local look = startCF.LookVector
		yaw = math.atan2(-look.X, -look.Z)
		pitch = math.asin(look.Y)

		camConn = RunService.RenderStepped:Connect(function()
			local delta = UIS:GetMouseDelta()

			yaw -= delta.X * 0.002
			pitch -= delta.Y * 0.002
			pitch = math.clamp(pitch, -1.4, 1.4)

			local rot = CFrame.fromOrientation(pitch, yaw, 0)
			Camera.CFrame = CFrame.new(Camera.CFrame.Position) * rot
		end)
	end

	local function disableFreecam()
		if not enabled then return end
		enabled = false

		if camConn then
			camConn:Disconnect()
			camConn = nil
		end

		-- restore camera
		Camera.CameraType = saved.CameraType
		Camera.CameraSubject = saved.CameraSubject
		Camera.CFrame = saved.CameraCFrame

		-- restore player
		if humanoid then
			humanoid.WalkSpeed = saved.WalkSpeed
			humanoid.JumpPower = saved.JumpPower
			humanoid.AutoRotate = saved.AutoRotate
		end
	end

	-- =========================
	-- GUI
	-- =========================

	for _,v in ipairs(Page:GetChildren()) do
		if v:IsA("Frame") and v.Name == "CactusFreecamFrame" then
			v:Destroy()
		end
	end

	local frame = Instance.new("Frame")
	frame.Name = "CactusFreecamFrame"
	frame.Size = UDim2.new(0,220,0,110)
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

	local toggle = Instance.new("TextButton")
	toggle.Size = UDim2.new(1,-20,0,30)
	toggle.Position = UDim2.new(0,10,0,44)
	toggle.BackgroundColor3 = Theme.BUTTON
	toggle.Text = "Freecam : OFF"
	toggle.Font = Enum.Font.Code
	toggle.TextSize = 14
	toggle.TextColor3 = Theme.TEXT_DIM
	toggle.BorderSizePixel = 0
	toggle.Parent = frame
	Instance.new("UICorner", toggle).CornerRadius = UDim.new(0,6)

	toggle.MouseButton1Click:Connect(function()
		if enabled then
			disableFreecam()
			toggle.Text = "Freecam : OFF"
			toggle.TextColor3 = Theme.TEXT_DIM
		else
			enableFreecam()
			toggle.Text = "Freecam : ON"
			toggle.TextColor3 = Theme.TEXT
		end
	end)

	-- safety
	LocalPlayer.CharacterAdded:Connect(function()
		task.wait()
		if enabled then
			disableFreecam()
			toggle.Text = "Freecam : OFF"
			toggle.TextColor3 = Theme.TEXT_DIM
		end
	end)
end

return Freecam

