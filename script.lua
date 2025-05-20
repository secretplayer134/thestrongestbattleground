-- LocalScript trong StarterPlayerScripts hoặc StarterCharacterScripts

local UserInputService = game:GetService("UserInputService")

-- Giả lập hành động khi nhấn phím D
local function onDPressed()
	print("Phím D được nhấn (giả lập)")
	-- Thêm logic của bạn ở đây
end

-- Giả lập hành động khi nhấn phím Q
local function onQPressed()
	print("Phím Q được nhấn (giả lập)")
	-- Thêm logic của bạn ở đây
end

-- Giả lập hành động khi nhấn phím 2
local function on2Pressed()
	print("Phím 2 được nhấn (giả lập)")
	-- Thêm logic của bạn ở đây
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	if input.KeyCode == Enum.KeyCode.One then
		print("Phím 1 được nhấn")
		task.delay(1, function()
			onDPressed()
			onQPressed()
			on2Pressed()
		end)
	end
end)


