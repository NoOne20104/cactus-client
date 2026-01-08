-- Cactus Bot TEST – Waypoint only

local Bot = {}

function Bot.Init(Client)

	local PathfindingService = game:GetService("PathfindingService")
	local LOCAL_PLAYER = Client.Player

	local humanoid
	local rootPart
	local currentTarget

	print("[TEST BOT] Loaded")

	-- =========================
	-- Character
	-- =========================

	local function getCharacter()
		local char = LOCAL_PLAYER.Character or LOCAL_PLAYER.CharacterAdded:Wait()
		humanoid = char:WaitForChild("Humanoid")
		rootPart = char:WaitForChild("HumanoidRootPart")
	end

	getCharacter()
	LOCAL_PLAYER.CharacterAdded:Connect(function()
		task.wait(1)
		getCharacter()
	end)

	-- =========================
	-- Path visuals
	-- =========================

	local folder = Instance.new("Folder", workspace)
	folder.Name = "Cactus_Test_Path"

	local function clear()
		for _,v in ipairs(folder:GetChildren()) do
			v:Destroy()
		end
	end

	local function draw(points)
		clear()
		local last
		for _,wp in ipairs(points) do
			local p = Instance.new("Part")
			p.Size = Vector3.new(0.2,0.2,0.2)
			p.Anchored = true
			p.CanCollide = false
			p.Transparency = 1
			p.Position = wp.Position
			p.Parent = folder

			local a = Instance.new("Attachment", p)

			if last then
				local b = Instance.new("Beam")
				b.Attachment0 = last
				b.Attachment1 = a
				b.FaceCamera = true
				b.Width0 = 0.15
				b.Width1 = 0.15
				b.Color = ColorSequence.new(Color3.fromRGB(0,255,90))
				b.LightEmission = 1
				b.Parent = p
			end

			last = a
		end
	end

	-- =========================
	-- PUBLIC API (Waypoints)
	-- =========================

	function Bot.GotoPosition(pos)
		print("[TEST BOT] GotoPosition called:", pos)
		if typeof(pos) ~= "Vector3" then return end
		currentTarget = pos
	end

	-- =========================
	-- Main loop
	-- =========================

	task.spawn(function()
		while true do
			task.wait(0.5)

			if not currentTarget or not rootPart then continue end

			local path = PathfindingService:CreatePath()
			path:ComputeAsync(rootPart.Position, currentTarget)

			if path.Status == Enum.PathStatus.Success then
				local wps = path:GetWaypoints()
				draw(wps)

				for _,wp in ipairs(wps) do
					if wp.Action == Enum.PathWaypointAction.Jump then
						humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
					end
					humanoid:MoveTo(wp.Position)
					humanoid.MoveToFinished:Wait()
				end
			end

			currentTarget = nil
		end
	end)
end

return Bot
