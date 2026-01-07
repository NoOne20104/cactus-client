-- NoClip Module (Cactus Client)

local NoClip = {}

function NoClip.Init(Client)

    local RunService = Client.Services.RunService
    local LocalPlayer = Client.Player

    Client.State.NoClip = {
        Enabled = false
    }

    local conn

    local function setNoClip(state)
        Client.State.NoClip.Enabled = state

        if conn then
            conn:Disconnect()
            conn = nil
        end

        if state then
            conn = RunService.Stepped:Connect(function()
                local char = LocalPlayer.Character
                if not char then return end

                for _, v in ipairs(char:GetDescendants()) do
                    if v:IsA("BasePart") then
                        v.CanCollide = false
                    end
                end
            end)
        end
    end

    -- public toggle
    function Client.State.NoClip.Toggle()
        setNoClip(not Client.State.NoClip.Enabled)
    end

    -- safety reset on respawn
    LocalPlayer.CharacterAdded:Connect(function()
        task.wait(1)
        if Client.State.NoClip.Enabled then
            setNoClip(true)
        end
    end)

end

return NoClip
