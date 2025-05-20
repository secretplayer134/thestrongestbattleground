-- 📁 LocalScript trong StarterPlayerScripts

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local flying = false
local flySpeed = 100
local followDistance = 2
local following = false
local currentTarget = nil
local isTyping = false

-- 🔀 Tọa độ dịch chuyển
local teleportLocations = {
    C = Vector3.new(0, 0, 0),
    V = Vector3.new(100, 442, -10)
}

-- 💨 Bay
local bg, bv, flyConn

local function createFlyParts(hrp)
    bg = Instance.new("BodyGyro")
    bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
    bg.P = 10000
    bg.CFrame = hrp.CFrame
    bg.Parent = hrp

    bv = Instance.new("BodyVelocity")
    bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    bv.Velocity = Vector3.new(0, 0, 0)
    bv.Parent = hrp
end

local function startFlying()
    if flying then return end
    flying = true

    local character = player.Character or player.CharacterAdded:Wait()
    local hrp = character:WaitForChild("HumanoidRootPart")
    createFlyParts(hrp)

    flyConn = RunService.RenderStepped:Connect(function()
        if not flying then return end
        local cam = workspace.CurrentCamera
        bg.CFrame = cam.CFrame
        bv.Velocity = cam.CFrame.LookVector * flySpeed
    end)
end

local function stopFlying()
    flying = false
    if flyConn then flyConn:Disconnect() end
    if bg then bg:Destroy() end
    if bv then bv:Destroy() end
end

-- 🧍‍♂️ Theo người chơi
local function getClosestPlayerInSight()
    local camera = workspace.CurrentCamera
    local closestPlayer = nil
    local smallestAngle = math.huge

    for _, otherPlayer in ipairs(Players:GetPlayers()) do
        if otherPlayer ~= player and otherPlayer.Character and otherPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local hrp = otherPlayer.Character.HumanoidRootPart
            local dirToPlayer = (hrp.Position - camera.CFrame.Position).Unit
            local angle = math.acos(camera.CFrame.LookVector:Dot(dirToPlayer))

            if angle < math.rad(30) and angle < smallestAngle then
                smallestAngle = angle
                closestPlayer = otherPlayer
            end
        end
    end

    return closestPlayer
end

RunService.RenderStepped:Connect(function()
    if following and currentTarget and currentTarget.Character and currentTarget.Character:FindFirstChild("HumanoidRootPart") then
        local targetHRP = currentTarget.Character.HumanoidRootPart
        local myChar = player.Character or player.CharacterAdded:Wait()
        local myHRP = myChar:FindFirstChild("HumanoidRootPart")

        if myHRP then
            local offset = -targetHRP.CFrame.LookVector * followDistance
            local newPos = targetHRP.Position + offset
            myHRP.CFrame = CFrame.new(newPos, targetHRP.Position)
        end
    end
end)

player.CharacterAdded:Connect(function()
    if flying then
        task.wait(1)
        startFlying()
    end
end)

-- 🧭 Dịch chuyển nhanh
local function teleportCharacter(key)
    local character = player.Character or player.CharacterAdded:Wait()
    local hrp = character:FindFirstChild("HumanoidRootPart")
    local destination = teleportLocations[key]

    if destination and hrp then
        hrp.CFrame = CFrame.new(destination)
    end
end

-- 📦 Tạo GUI
local function createGUI()
    local gui = Instance.new("ScreenGui")
    gui.Name = "FlyMenuGui"
    gui.ResetOnSpawn = false
    gui.Parent = player:WaitForChild("PlayerGui")

    local frame = Instance.new("Frame")
    frame.Name = "MainFrame"
    frame.Size = UDim2.new(0, 300, 0, 250)
    frame.Position = UDim2.new(1, -310, 1, -260)
    frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    frame.BorderSizePixel = 0
    frame.Visible = false
    frame.Parent = gui

    local infoLabels = {}
    for i = 1, 5 do
        local label = Instance.new("TextLabel")
        label.Name = "Info" .. i
        label.Size = UDim2.new(1, -10, 0, 25)
        label.Position = UDim2.new(0, 5, 0, 5 + (i - 1) * 26)
        label.BackgroundTransparency = 1
        label.TextColor3 = Color3.new(1, 1, 1)
        label.Font = Enum.Font.Gotham
        label.TextSize = 14
        label.Text = "" -- Không có '...'
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = frame
        infoLabels[i] = label
    end

    local function createButton(name, text, yPos)
        local btn = Instance.new("TextButton")
        btn.Name = name
        btn.Size = UDim2.new(1, -10, 0, 30)
        btn.Position = UDim2.new(0, 5, 0, yPos)
        btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        btn.TextColor3 = Color3.new(1, 1, 1)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 14
        btn.Text = text
        btn.Parent = frame
        return btn
    end

    local increaseBtn = createButton("IncreaseSpeedBtn", "faster", 140)
    local decreaseBtn = createButton("DecreaseSpeedBtn", "slower", 175)
    local adjustFollowBtn = createButton("AdjustFollowBtn", "adjust distance (max: 10)", 210)

    local function updateInfo()
        infoLabels[1].Text = "fly speed: " .. tostring(flySpeed)
        infoLabels[2].Text = "R to fly"
        infoLabels[3].Text = "E to follow player"
        infoLabels[4].Text = "distance: " .. tostring(followDistance)
        infoLabels[5].Text = "Right Shift to close/open"
    end

    increaseBtn.MouseButton1Click:Connect(function()
        flySpeed += 10
        updateInfo()
    end)

    decreaseBtn.MouseButton1Click:Connect(function()
        flySpeed = math.max(10, flySpeed - 10)
        updateInfo()
    end)

    adjustFollowBtn.MouseButton1Click:Connect(function()
        followDistance += 1
        if followDistance > 10 then followDistance = 1 end
        updateInfo()
    end)

    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if input.KeyCode == Enum.KeyCode.RightShift then
            frame.Visible = not frame.Visible
            updateInfo()
        end
    end)

    updateInfo() -- cập nhật ngay khi tạo GUI
end

createGUI()

-- 🎮 Điều khiển phím bấm
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    if input.KeyCode == Enum.KeyCode.R then
        if flying then stopFlying() else startFlying() end

    elseif input.KeyCode == Enum.KeyCode.C then
        teleportCharacter("C")
    elseif input.KeyCode == Enum.KeyCode.V then
        teleportCharacter("V")

    elseif input.KeyCode == Enum.KeyCode.E then
        if not following then
            currentTarget = getClosestPlayerInSight()
            if currentTarget then
                following = true
            end
        else
            following = false
            currentTarget = nil
        end
    elseif input.KeyCode == Enum.KeyCode.KeypadOne then
        -- Điều chỉnh tốc độ bay bằng số 1 trên bàn phím
        flySpeed = 50
        updateInfo()
    elseif input.KeyCode == Enum.KeyCode.KeypadTwo then
        -- Điều chỉnh tốc độ bay bằng số 2
        flySpeed = 100
        updateInfo()
    elseif input.KeyCode == Enum.KeyCode.KeypadThree then
        -- Điều chỉnh tốc độ bay bằng số 3
        flySpeed = 150
        updateInfo()
    elseif input.KeyCode == Enum.KeyCode.KeypadFour then
        -- Điều chỉnh tốc độ bay bằng số 4
        flySpeed = 200
        updateInfo()
    end
end)



