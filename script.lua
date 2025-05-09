local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local flying = false
local speed = 100

local bg
local bv
local flyConn

local followDistance = 2
local following = false
local currentTarget = nil

local teleportLocations = {
	C = Vector3.new( 0, 0, 0),
	V = Vector3.new(100, 442, -10)
}

-- Tạo phần tử bay
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

-- Bắt đầu bay
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
		local moveDir = cam.CFrame.LookVector * speed
		bv.Velocity = moveDir
	end)
end

-- Dừng bay
local function stopFlying()
	flying = false
	if flyConn then flyConn:Disconnect() end
	if bg then bg:Destroy() end
	if bv then bv:Destroy() end
end

-- Dịch chuyển nhân vật
local function teleportCharacter(key)
	local character = player.Character or player.CharacterAdded:Wait()
	local hrp = character:FindFirstChild("HumanoidRootPart")
	local destination = teleportLocations[key]

	if destination and hrp then
		hrp.CFrame = CFrame.new(destination)
	end
end

-- Tìm người chơi gần nhất trong tầm nhìn
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

-- Xử lý phím bấm
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	if input.KeyCode == Enum.KeyCode.R then
		if flying then
			stopFlying()
		else
			startFlying()
		end

	elseif input.KeyCode == Enum.KeyCode.C then
		teleportCharacter("C")
	elseif input.KeyCode == Enum.KeyCode.V then
		teleportCharacter("V")

	elseif input.KeyCode == Enum.KeyCode.E then
		if not following then
			currentTarget = getClosestPlayerInSight()
			if currentTarget then
				following = true
				print("🔁 Đang bám theo:", currentTarget.Name)
			else
				warn("❌ Không tìm thấy người chơi trong tầm nhìn.")
			end
		else
			following = false
			currentTarget = nil
			print("⛔ Đã dừng bám theo.")
		end
	end
end)

-- Cập nhật vị trí khi bám theo
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

-- Tự động khôi phục khi respawn
player.CharacterAdded:Connect(function()
	if flying then
		task.wait(1)
		startFlying()
	end
end)

