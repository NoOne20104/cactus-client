local Freecam = {}

function Freecam.Init(Client)

	-- =========================
	-- Services / Core
	-- =========================

	local UIS = game:GetService("UserInputService")
	local CAS = game:GetService("ContextActionService")
	local RunService = Client.Services.RunService
	local LocalPlayer = Client.Player
	local Page = Client.Pages.Freecam
	local Theme = Client.Theme
	local Camera = workspace.CurrentCamera

	-- =========================
	-- State
	-- =========================

	Freecam.Enabled = false
	Freecam.ControlPlayer = false
	Freecam.Speed = 60
	Freecam.Sensitivity = 0.25

	local camConn
	local yaw = 0
	local pitch = 0
	local saved = {}

	-- =========================
	-- Input block
	-- =========================

	local function blockControls()
		CAS:BindAction(
			"FreecamBlock",
			function() return Enum.ContextActionResult.Sink end,
			false,
			Enum.PlayerActions.CharacterForward,
			Enum.PlayerActions.CharacterBackward,
			Enum.PlayerActions.CharacterLeft,
			Enum.PlayerActions.CharacterRight,
			Enum.PlayerActions.CharacterJump
		)
	end

	local function unblockControls()
		CAS:UnbindAction("FreecamBlock")
	end

	-- =========================
	-- Core Freecam (LOGIC UNCHANGED)
	-- =========================

	local function startFreecam()
		if Freecam.Enabled then return end
		if not Camera then return end

		Freecam.Enabled = true

		saved.Type = Camera.CameraType
		saved.Subject = Camera.CameraSubject
		saved.CFrame = Camera.CFrame
		saved.MouseBehavior = UIS.MouseBehavior
		saved.MouseIcon = UIS.MouseIconEnabled

		Camera.CameraType = Enum.CameraType.Scriptable
		UIS.MouseBehavior = Enum.MouseBehavior.LockCenter
		UIS.MouseIconEnabled = false

		if not Freecam.ControlPlayer then
			blockControls()
		end

		local cf = Camera.CFrame
		local look = cf.LookVector
		yaw = math.atan2(-look.X, -look.Z)
		pitch = math.asin(look.Y)

		camConn = RunService.RenderStepped:Connect(function(dt)

			local delta = UIS:GetMouseDelta()
			yaw -= delta.X * Freecam.Sensitivity * 0.01
			pitch -= delta.Y * Freecam.Sensitivity * 0.01
			pitch = math.clamp(pitch, -1.5, 1.5)

			local rot = CFrame.fromOrientation(pitch, yaw, 0)

			local dir = Vector3.zero
			if UIS:IsKeyDown(Enum.KeyCode.W) then dir += rot.LookVector end
			if UIS:IsKeyDown(Enum.KeyCode.S) then dir -= rot.LookVector end
			if UIS:IsKeyDown(Enum.KeyCode.A) then dir -= rot.RightVector end
			if UIS:IsKeyDown(Enum.KeyCode.D) then dir += rot.RightVector end
			if UIS:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.new(0,1,0) end
			if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then dir -= Vector3.new(0,1,0) end

			if dir.Magnitude > 0 then
				dir = dir.Unit * Freecam.Speed * dt
			end

			Camera.CFrame = CFrame.new(Camera.CFrame.Position + dir) * rot
		end)
	end

	local function stopFreecam()
		if not Freecam.Enabled then return end
		Freecam.Enabled = false

		if camConn then camConn:Disconnect() camConn = nil end

		unblockControls()

		if Camera then
			Camera.CameraType = saved.Type
			Camera.CameraSubject = saved.Subject
			Camera.CFrame = saved.CFrame
		end

		UIS.MouseBehavior = saved.MouseBehavior
		UIS.MouseIconEnabled = saved.MouseIcon
	end

	-- =========================
	-- GUI
	-- =========================

	for _,child in ipairs(Page:GetChildren()) do
		if child:IsA("Frame") and child.Name == "CactusFreecamFrame" then
			child:Destroy()
		end
	end

	local frame = Instance.new("Frame")
	frame.Name = "CactusFreecamFrame"
	frame.Size = UDim2.new(0,220,0,220)
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

	local holder = Instance.new("Frame")
	holder.Size = UDim2.new(1,-20,1,-40)
	holder.Position = UDim2.new(0,10,0,36)
	holder.BackgroundTransparency = 1
	holder.Parent = frame

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0,6)
	layout.Parent = holder

	local function makeButton(text)
		local b = Instance.new("TextButton")
		b.Size = UDim2.new(1,0,0,30)
		b.BackgroundColor3 = Theme.BUTTON
		b.Text = text
		b.Font = Enum.Font.Code
		b.TextSize = 14
		b.TextColor3 = Theme.TEXT_DIM
		b.BorderSizePixel = 0
		b.Parent = holder
		Instance.new("UICorner", b).CornerRadius = UDim.new(0,6)
		return b
	end

	local isoBtn = makeButton("Freecam (Isolated) : OFF")
	local controlBtn = makeButton("Freecam (Control Player) : OFF")

	-- =========================
	-- Buttons
	-- =========================

	isoBtn.MouseButton1Click:Connect(function()
		if Freecam.Enabled and not Freecam.ControlPlayer then
			stopFreecam()
			isoBtn.Text = "Freecam (Isolated) : OFF"
			isoBtn.TextColor3 = Theme.TEXT_DIM
			return
		end

		stopFreecam()
		Freecam.ControlPlayer = false
		startFreecam()

		isoBtn.Text = "Freecam (Isolated) : ON"
		isoBtn.TextColor3 = Theme.TEXT

		controlBtn.Text = "Freecam (Control Player) : OFF"
		controlBtn.TextColor3 = Theme.TEXT_DIM
	end)

	controlBtn.MouseButton1Click:Connect(function()
		if Freecam.Enabled and Freecam.ControlPlayer then
			stopFreecam()
			controlBtn.Text = "Freecam (Control Player) : OFF"
			controlBtn.TextColor3 = Theme.TEXT_DIM
			return
		end

		stopFreecam()
		Freecam.ControlPlayer = true
		startFreecam()

		controlBtn.Text = "Freecam (Control Player) : ON"
		controlBtn.TextColor3 = Theme.TEXT

		isoBtn.Text = "Freecam (Isolated) : OFF"
		isoBtn.TextColor3 = Theme.TEXT_DIM
	end)

	LocalPlayer.CharacterAdded:Connect(function()
		if Freecam.Enabled then
			task.wait(0.2)
			stopFreecam()
			isoBtn.Text = "Freecam (Isolated) : OFF"
			controlBtn.Text = "Freecam (Control Player) : OFF"
			isoBtn.TextColor3 = Theme.TEXT_DIM
			controlBtn.TextColor3 = Theme.TEXT_DIM
		end
	end)
end

return Freecam
