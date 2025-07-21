-- 📁 LocalScript trong StarterPlayerScripts

local Players = game:GetService("Players") local RunService = game:GetService("RunService") local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer local camera = workspace.CurrentCamera local flying = false local noclip = false local followDistance = 2 local following = false local currentTarget = nil local flySpeed = 100 local isTyping = false local guiVisible = true

local infoLabels = {}

-- 🔁 Cập nhật GUI local function updateInfo() if infoLabels[1] then infoLabels[1].Text = "Flying: " .. tostring(flying) infoLabels[2].Text = "Speed: " .. flySpeed infoLabels[3].Text = "Noclip: " .. (noclip and "ON" or "OFF") .. " | T to toggle" infoLabels[4].Text = "Following: " .. tostring(following) infoLabels[5].Text = "Follow Distance: " .. followDistance infoLabels[6].Text = "Keys: E Fly, T Noclip, R Follow, Q Stop, C Teleport" end end

-- 📦 Giao diện GUI local function createGUI() local gui = Instance.new("ScreenGui") gui.Name = "FlyMenuGui" gui.ResetOnSpawn = false gui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Name = "MainFrame"
frame.Size = UDim2.new(0, 300, 0, 280)
frame.Position = UDim2.new(1, -310, 1, -290)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.BorderSizePixel = 0
frame.Visible = true
frame.Parent = gui

for i = 1, 6 do
	local label = Instance.new("TextLabel")
	label.Name = "Info" .. i
	label.Size = UDim2.new(1, -10, 0, 25)
	label.Position = UDim2.new(0, 5, 0, 5 + (i - 1) * 26)
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.new(1, 1, 1)
	label.Font = Enum.Font.Gotham
	label.TextSize = 14
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Text = ""
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

local increaseBtn = createButton("IncreaseSpeedBtn", "faster", 180)
local decreaseBtn = createButton("DecreaseSpeedBtn", "slower", 215)
local adjustFollowBtn = createButton("AdjustFollowBtn", "adjust distance (max: 10)", 250)

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

-- 🔁 Toggle GUI bằng RightShift
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if input.KeyCode == Enum.KeyCode.RightShift then
		guiVisible = not guiVisible
		frame.Visible = guiVisible
	end
end)

updateInfo()

end

-- 🧲 Theo dõi người gần nhất local function getClosestPlayer() local minDist = math.huge local closest = nil for _, other in ipairs(Players:GetPlayers()) do if other ~= player and other.Character and other.Character:FindFirstChild("HumanoidRootPart") then local dist = (other.Character.HumanoidRootPart.Position - player.Character.HumanoidRootPart.Position).Magnitude if dist < minDist then minDist = dist closest = other end end end return closest end

-- 🕹️ Nhập phím điều khiển UserInputService.InputBegan:Connect(function(input, gameProcessed) if gameProcessed or isTyping then return end

local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
if not hrp then return end

if input.KeyCode == Enum.KeyCode.E then
	flying = not flying
	if flying then
		noclip = true
	end
elseif input.KeyCode == Enum.KeyCode.T then
	noclip = not noclip
elseif input.KeyCode == Enum.KeyCode.C then
	hrPosition = Vector3.new(10000, 0, 0)
	hr.CFrame = CFrame.new(hrPosition)
elseif input.KeyCode == Enum.KeyCode.R then
	currentTarget = getClosestPlayer()
	following = currentTarget ~= nil
elseif input.KeyCode == Enum.KeyCode.Q then
	following = false
	currentTarget = nil
end
updateInfo()

end)

-- ☁️ Chuyển động bay và theo người RunService.RenderStepped:Connect(function() if flying and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then local hrp = player.Character.HumanoidRootPart local moveDir = Vector3.zero if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir += camera.CFrame.LookVector end if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir -= camera.CFrame.LookVector end if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir -= camera.CFrame.RightVector end if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir += camera.CFrame.RightVector end if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir += camera.CFrame.UpVector end if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then moveDir -= camera.CFrame.UpVector end

hr.CFrame += moveDir.Unit * flySpeed * RunService.RenderStepped:Wait()
end

if following and currentTarget and currentTarget.Character and currentTarget.Character:FindFirstChild("HumanoidRootPart") then
	local targetPos = currentTarget.Character.HumanoidRootPart.Position + Vector3.new(0, followDistance, 0)
	local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if hrp then
		hr.CFrame = hrp.CFrame:Lerp(CFrame.new(targetPos), 0.1)
	end
end

if noclip and player.Character then
	for _, part in ipairs(player.Character:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CanCollide = false
		end
	end
end

end)

-- 🔧 Gọi hàm tạo GUI createGUI()

