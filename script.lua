-- Script cho executor, tạo Tool + GUI

local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- Tạo Tool nếu chưa có
local backpack = player:WaitForChild("Backpack")
local tool = Instance.new("Tool")
tool.Name = "Instruction"
tool.RequiresHandle = false
tool.Parent = backpack

-- Tạo GUI
local function createInstructionGUI()
    local gui = Instance.new("ScreenGui")
    gui.Name = "InstructionGUI"
    gui.ResetOnSpawn = false
    gui.Parent = player:WaitForChild("PlayerGui")

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 350, 0, 153) -- tăng thêm 0.5 dòng từ 137 -> 153
    frame.Position = UDim2.new(0.5, -175, 0.5, -76)
    frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    frame.BorderSizePixel = 0
    frame.Visible = false
    frame.Parent = gui
    frame.AnchorPoint = Vector2.new(0.5,0.5)
    frame.ClipsDescendants = true

    -- Nút icon X đỏ
    local closeBtn = Instance.new("ImageButton")
    closeBtn.Size = UDim2.new(0, 35, 0, 35)
    closeBtn.Position = UDim2.new(1, -45, 0, 5)
    closeBtn.Image = "rbxassetid://6031094678" -- icon X đỏ
    closeBtn.BackgroundTransparency = 1
    closeBtn.Parent = frame
    closeBtn.MouseButton1Click:Connect(function()
        frame.Visible = false
    end)

    -- 8 dòng hướng dẫn
    local instructions = {
        "E to follow player",
        "R to fly",
        "T to toggle noclip",
        "Y to teleport",
        "V to go back to ground (for TSB)",
        "C to teleport to void",
        "You can zoom as far as you want",
        "RightShift to open another GUI"
    }

    local lineHeight = 17
    local topOffset = 10

    for i, text in ipairs(instructions) do
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -20, 0, lineHeight)
        label.Position = UDim2.new(0, 10, 0, topOffset + (i-1)*lineHeight)
        label.BackgroundTransparency = 1
        label.TextColor3 = Color3.new(1,1,1)
        label.Font = Enum.Font.GothamBold
        label.TextSize = 16
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Text = text
        label.Parent = frame
    end

    -- Kéo GUI
    local dragging, dragInput, dragStart, startPos
    local function update(input)
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end

    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    frame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)

    player:GetMouse().Move:Connect(function()
        if dragging and dragInput then
            update(dragInput)
        end
    end)

    return frame
end

local guiFrame = createInstructionGUI()

-- Khi Tool trên hotbar được chọn sẽ hiện GUI luôn
tool.Equipped:Connect(function()
    guiFrame.Visible = true
end)                                                                                                                                         -- 📁 LocalScript trong StarterPlayerScripts

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local mouse = player:GetMouse()
local flying = false
local flySpeed = 100
local followDistance = 2
local following = false
local currentTarget = nil
local noclipEnabled = false

-- 🟢 Gỡ giới hạn zoom camera
player.CameraMaxZoomDistance = 1e9
player.CameraMinZoomDistance = 0.5

-- 🔀 Tọa độ dịch chuyển nhanh
local teleportLocations = {
	C = Vector3.new(10000, 0, 0),
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

-- 🟡 Teleport tới vị trí chuột khi nhấn Y
local function teleportToMouse()
	local char = player.Character
	if char and char:FindFirstChild("HumanoidRootPart") and mouse.Hit then
		char.HumanoidRootPart.CFrame = CFrame.new(mouse.Hit.p + Vector3.new(0, 3, 0))
	end
end

-- 🧱 Noclip
local noclipConn
local function setNoclip(state)
	noclipEnabled = state
	if noclipConn then noclipConn:Disconnect() end
	if state then
		noclipConn = RunService.Stepped:Connect(function()
			local character = player.Character
			if character then
				for _, part in pairs(character:GetDescendants()) do
					if part:IsA("BasePart") then
						part.CanCollide = false
					end
				end
			end
		end)
	end
end

-- 📦 GUI rút gọn, giữ các nút điều chỉnh
local guiFrame, infoLabels
local function updateInfo()
	infoLabels[1].Text = "Fly speed: " .. tostring(flySpeed)
	infoLabels[2].Text = "Noclip: " .. (noclipEnabled and "on" or "off")
	infoLabels[3].Text = "Follow distance: " .. tostring(followDistance)
end

local function createGUI()
	local gui = Instance.new("ScreenGui")
	gui.Name = "FlyMenuGui"
	gui.ResetOnSpawn = false
	gui.Parent = player:WaitForChild("PlayerGui")

	guiFrame = Instance.new("Frame")
	guiFrame.Size = UDim2.new(0, 300, 0, 180)
	guiFrame.Position = UDim2.new(1, -310, 1, -190)
	guiFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	guiFrame.BorderSizePixel = 0
	guiFrame.Visible = false
	guiFrame.Parent = gui

	-- Info Labels
	infoLabels = {}
	for i = 1, 3 do
		local lbl = Instance.new("TextLabel")
		lbl.Size = UDim2.new(1, -10, 0, 25)
		lbl.Position = UDim2.new(0, 5, 0, 5 + (i-1)*30)
		lbl.BackgroundTransparency = 1
		lbl.TextColor3 = Color3.new(1,1,1)
		lbl.Font = Enum.Font.Gotham
		lbl.TextSize = 14
		lbl.TextXAlignment = Enum.TextXAlignment.Left
		lbl.Parent = guiFrame
		infoLabels[i] = lbl
	end

	-- Buttons
	local function createButton(name, text, yPos)
		local btn = Instance.new("TextButton")
		btn.Name = name
		btn.Size = UDim2.new(1,-10,0,30)
		btn.Position = UDim2.new(0,5,0,yPos)
		btn.BackgroundColor3 = Color3.fromRGB(50,50,50)
		btn.TextColor3 = Color3.new(1,1,1)
		btn.Font = Enum.Font.GothamBold
		btn.TextSize = 14
		btn.Text = text
		btn.Parent = guiFrame
		return btn
	end

	local increaseBtn = createButton("IncreaseSpeedBtn","faster",100)
	local decreaseBtn = createButton("DecreaseSpeedBtn","slower",135)
	local adjustFollowBtn = createButton("AdjustFollowBtn","adjust distance (max:10)",170)

	increaseBtn.MouseButton1Click:Connect(function()
		flySpeed += 10
		updateInfo()
	end)
	decreaseBtn.MouseButton1Click:Connect(function()
		flySpeed = math.max(10, flySpeed-10)
		updateInfo()
	end)
	adjustFollowBtn.MouseButton1Click:Connect(function()
		followDistance += 1
		if followDistance > 10 then followDistance = 1 end
		updateInfo()
	end)

	UserInputService.InputBegan:Connect(function(input)
		if input.KeyCode == Enum.KeyCode.RightShift then
			guiFrame.Visible = not guiFrame.Visible
			updateInfo()
		end
	end)

	updateInfo()
end

createGUI()

-- 🎮 Phím điều khiển
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	if input.KeyCode == Enum.KeyCode.R then
		if flying then stopFlying() else startFlying() end
	elseif input.KeyCode == Enum.KeyCode.C then
		teleportCharacter("C")
	elseif input.KeyCode == Enum.KeyCode.V then
		teleportCharacter("V")
	elseif input.KeyCode == Enum.KeyCode.Y then
		teleportToMouse()
	elseif input.KeyCode == Enum.KeyCode.E then
		if not following then
			currentTarget = getClosestPlayerInSight()
			if currentTarget then following = true end
		else
			following = false
			currentTarget = nil
		end
	elseif input.KeyCode == Enum.KeyCode.T then
		setNoclip(not noclipEnabled)
	elseif input.KeyCode == Enum.KeyCode.KeypadOne then flySpeed=50
	elseif input.KeyCode == Enum.KeyCode.KeypadTwo then flySpeed=100
	elseif input.KeyCode == Enum.KeyCode.KeypadThree then flySpeed=150
	elseif input.KeyCode == Enum.KeyCode.KeypadFour then flySpeed=200
	end

	updateInfo()
end)                                                                                                                                      
