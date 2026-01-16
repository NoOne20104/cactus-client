local TPGhost = {}

function TPGhost.Init(Client)

	-- =========================
	-- Services / Core
	-- =========================

	local Players = game:GetService("Players")
	local UserInputService = game:GetService("UserInputService")
	local RunService = Client.Services.RunService

	local player = Client.Player
	local Page = Client.Pages.TPGhost
	local Theme = Client.Theme

	local camera = workspace.CurrentCamera

	-- =========================
	-- Character handling (UNCHANGED)
	-- =========================

	local character, humanoid, root, head

	local function hookCharacter(char)
		character = char
		humanoid = char:WaitForChild("Humanoid")
		root = char:WaitForChild("HumanoidRootPart")
		head = char:WaitForChild("Head")

		camera.CameraType = Enum.CameraType.Custom
		camera.CameraSubject = humanoid
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	end

	hookCharacter(player.Character or player.CharacterAdded:Wait())
	player.CharacterAdded:Connect(hookCharacter)

	-- =========================
	-- State (UNCHANGED)
	-- =========================

	local enabled = false
	local atStart = false

	local startCFrame = nil
	local savedMoveCFrame = nil

	local cameraGhost = nil
	local frozenClone = nil

	-- =========================
	-- Enable / Disable (UNCHANGED)
	-- =========================

	local function enableTPGhost()
		if not root then return end

		enabled = true
		atStart = false

		startCFrame = root.CFrame
		savedMoveCFrame = root.CFrame

		if cameraGhost then
			cameraGhost:Destroy()
			cameraGhost = nil
		end

		if frozenClone then
			frozenClone:Destroy()
			frozenClone = nil
		end

		camera.CameraSubject = humanoid
	end

	local function disableTPGhost()
		enabled = false
		atStart = false

		startCFrame = nil
		savedMoveCFrame = nil

		if cameraGhost then
			cameraGhost:Destroy()
			cameraGhost = nil
		end

		if frozenClone then
			frozenClone:Destroy()
			frozenClone = nil
		end

		if humanoid then
			camera.CameraSubject = humanoid
		end
	end

	-- =========================
	-- Core loop (UNCHANGED)
	-- =========================

	RunService.Heartbeat:Connect(function()
		if not enabled then return end
		if not humanoid or not root then return end
		if not startCFrame then return end

		local moving = humanoid.MoveDirection.Magnitude > 0.05

		if moving then
			if atStart then
				atStart = false

				if savedMoveCFrame then
					root.CFrame = savedMoveCFrame
				end

				if cameraGhost then
					camera.CameraSubject = humanoid
					cameraGhost:Destroy()
					cameraGhost = nil
				end

				if frozenClone then
					frozenClone:Destroy()
					frozenClone = nil
				end
			else
				savedMoveCFrame = root.CFrame
			end
		else
			if not atStart and savedMoveCFrame then
				atStart = true

				local part = Instance.new("Part")
				part.Size = Vector3.new(1,1,1)
				part.Transparency = 1
				part.CanCollide = false
				part.Anchored = true
				part.CFrame = CFrame.new((head and head.Position) or root.Position)
				part.Name = "CameraGhost"
				part.Parent = workspace

				cameraGhost = part
				camera.CameraSubject = part

				pcall(function()
					if character then
						character.Archivable = true
						local clone = character:Clone()
						clone.Name = "FrozenClone"
						clone.Parent = workspace

						if clone.PrimaryPart then
							clone:SetPrimaryPartCFrame(savedMoveCFrame)
						else
							clone:MoveTo(savedMoveCFrame.Position)
						end

						for _, v in ipairs(clone:GetDescendants()) do
							if v:IsA("BasePart") then
								v.Anchored = true
								v.CanCollide = false
							end
						end

						frozenClone = clone
					end
				end)

				root.CFrame = startCFrame
			end
		end
	end)

	-- =========================
	-- GUI (REWRITTEN, SAFE)
	-- =========================

	for _, child in ipairs(Page:GetChildren()) do
		if child:IsA("Frame") and child.Name == "CactusTPGhostFrame" then
			child:Destroy()
		end
	end

	local frame = Instance.new("Frame")
	frame.Name = "CactusTPGhostFrame"
	frame.Size = UDim2.new(0,220,0,200)
	frame.Position = UDim2.new(0,10,0,10)
	frame.BackgroundColor3 = Color3.fromRGB(14,14,14)
	frame.BorderSizePixel = 0
	frame.Parent = Page
	Instance.new("UICorner", frame).CornerRadius = UDim.new(0,10)

	local stroke = Instance.new("UIStroke")
	stroke.Color = Theme.STROKE
	stroke.Transparency = 0.4
	stroke.Parent = frame

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1,-12,0,26)
	title.Position = UDim2.new(0,10,0,4)
	title.BackgroundTransparency = 1
	title.Text = "TP Ghost"
	title.Font = Enum.Font.Code
	title.TextSize = 16
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextColor3 = Theme.TEXT
	title.Parent = frame

	local holder = Instance.new("Frame")
	holder.Size = UDim2.new(1,-20,0,0)
	holder.Position = UDim2.new(0,10,0,36)
	holder.BackgroundTransparency = 1
	holder.AutomaticSize = Enum.AutomaticSize.Y
	holder.Parent = frame

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0,6)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = holder

	local function makeButton(text, order)
		local b = Instance.new("TextButton")
		b.Size = UDim2.new(1,0,0,30)
		b.BackgroundColor3 = Theme.BUTTON
		b.Text = text
		b.Font = Enum.Font.Code
		b.TextSize = 14
		b.TextColor3 = Theme.TEXT_DIM
		b.BorderSizePixel = 0
		b.LayoutOrder = order
		b.AutoButtonColor = false
		b.Parent = holder
		b.ZIndex = 2
		Instance.new("UICorner", b).CornerRadius = UDim.new(0,6)

		local s = Instance.new("UIStroke")
		s.Color = Theme.STROKE
		s.Transparency = 0.7
		s.Thickness = 1
		s.Parent = b

		return b
	end

	local enableBtn  = makeButton("TPGhost : OFF", 10)
	local disableBtn = makeButton("Disable TPGhost", 30)

	-- =========================
	-- Buttons (UNCHANGED LOGIC)
	-- =========================

	enableBtn.MouseButton1Click:Connect(function()
		enableTPGhost()
		enableBtn.Text = "TPGhost : ON"
		enableBtn.TextColor3 = Theme.TEXT
	end)

	disableBtn.MouseButton1Click:Connect(function()
		disableTPGhost()
		enableBtn.Text = "TPGhost : OFF"
		enableBtn.TextColor3 = Theme.TEXT_DIM
	end)
end

return TPGhost
