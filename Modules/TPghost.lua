local TPghost = {}

function TPghost.Init(Client)

	-- =========================
	-- Services / Core
	-- =========================

	local UserInputService = game:GetService("UserInputService")
	local RunService = Client.Services.RunService

	local player = Client.Player
	local Page = Client.Pages.TPghost
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
	-- Return outline system (NEW, VISUAL ONLY)
	-- =========================

	local returnOutline = nil
	local distanceLabel = nil
	local showOutline = false
	local distanceConn = nil

	local function destroyReturnOutline()
		if distanceConn then
			distanceConn:Disconnect()
			distanceConn = nil
		end

		if returnOutline then
			returnOutline:Destroy()
			returnOutline = nil
		end
	end

	local function createReturnOutline(cf)
		if not character then return end

		destroyReturnOutline()

		pcall(function()
			character.Archivable = true
			local clone = character:Clone()
			clone.Name = "TPghostReturnOutline"
			clone.Parent = workspace

			if clone.PrimaryPart then
				clone:SetPrimaryPartCFrame(cf)
			else
				clone:MoveTo(cf.Position)
			end

			for _, v in ipairs(clone:GetDescendants()) do
				if v:IsA("BasePart") then
					v.Anchored = true
					v.CanCollide = false
					v.Material = Enum.Material.Neon
					v.Color = Theme.TEXT
					v.Transparency = 0.35

				elseif v:IsA("Decal") or v:IsA("Texture") or v:IsA("SurfaceAppearance") then
					v:Destroy()

				elseif v:IsA("Shirt") or v:IsA("Pants") or v:IsA("ShirtGraphic") then
					v:Destroy()

				elseif v:IsA("Accessory") or v:IsA("Humanoid") then
					v:Destroy()

				elseif v:IsA("Script") or v:IsA("LocalScript") then
					v:Destroy()
				end
			end

			-- ===== Distance label =====

			local adornee = clone:FindFirstChild("Head") or clone.PrimaryPart
			if adornee then
				local bill = Instance.new("BillboardGui")
				bill.Name = "TPghostDistance"
				bill.Adornee = adornee
				bill.Size = UDim2.new(0,140,0,32)
				bill.StudsOffset = Vector3.new(0,2.6,0)
				bill.AlwaysOnTop = true
				bill.Parent = clone

				local txt = Instance.new("TextLabel")
				txt.Size = UDim2.new(1,0,1,0)
				txt.BackgroundTransparency = 1
				txt.Text = "0.0m"
				txt.Font = Enum.Font.Code
				txt.TextSize = 14
				txt.TextColor3 = Theme.TEXT
				txt.TextStrokeTransparency = 0.3
				txt.Parent = bill

				distanceLabel = txt
			end

			returnOutline = clone

			-- ===== Live distance updater (VISUAL ONLY) =====

			distanceConn = RunService.Heartbeat:Connect(function()
				if not returnOutline or not root or not startCFrame or not distanceLabel then return end
				local dist = (root.Position - startCFrame.Position).Magnitude
				distanceLabel.Text = string.format("Distance: %.1f", dist)
			end)
		end)
	end

	-- =========================
	-- Enable / Disable (UNCHANGED LOGIC, outline calls added)
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

		if showOutline then
			createReturnOutline(startCFrame)
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

		destroyReturnOutline()

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
	-- GUI (UNCHANGED LOGIC)
	-- =========================
	-- (your existing GUI block here – unchanged)
	-- ESP button still toggles showOutline and calls create/destroy
end

return TPghost
