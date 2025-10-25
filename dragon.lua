-- Fly script (LocalScript)
-- ضع هذا الملف في StarterPlayer > StarterPlayerScripts

local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local character = nil
local hrp = nil -- HumanoidRootPart
local humanoid = nil
local camera = workspace.CurrentCamera

local flyEnabled = false
local speed = 60 -- سرعة الطيران (يمكن تعديلها)
local ascendSpeed = 40 -- سرعة الصعود/النزول عند الضغط على Space/LeftControl
local bv, bg -- BodyVelocity و BodyGyro
local connection -- للـ RenderStepped

-- حركة مُدخلات
local moveVector = Vector3.new(0,0,0)
local vertical = 0 -- 1 صعود، -1 نزول، 0 لا شيء

-- تتبع تغيّر الشخصية (عند respawn)
local function onCharacterAdded(char)
    character = char
    humanoid = character:WaitForChild("Humanoid", 5)
    hrp = character:WaitForChild("HumanoidRootPart", 5)
    -- إن تم تمكين الطيران قبل respawn، نوقفه تلقائياً (أمان)
    if flyEnabled then
        flyEnabled = false
        if bv then bv:Destroy(); bv = nil end
        if bg then bg:Destroy(); bg = nil end
        if connection then connection:Disconnect(); connection = nil end
        if humanoid then
            pcall(function() humanoid.PlatformStand = false end)
        end
    end
end

if player.Character then
    onCharacterAdded(player.Character)
end
player.CharacterAdded:Connect(onCharacterAdded)

-- إنشاء أو تدمير المكونات الفيزيائية للطيران
local function enableFly()
    if not hrp then return end
    if flyEnabled then return end
    flyEnabled = true

    -- منع السقوط الطبيعي
    if humanoid then
        pcall(function() humanoid.PlatformStand = true end)
    end

    -- BodyVelocity
    bv = Instance.new("BodyVelocity")
    bv.MaxForce = Vector3.new(1e5, 1e5, 1e5)
    bv.P = 1e4
    bv.Velocity = Vector3.new(0,0,0)
    bv.Parent = hrp

    -- BodyGyro للحفاظ على وجهة الجسم بما تتجه اليه الكاميرا
    bg = Instance.new("BodyGyro")
    bg.MaxTorque = Vector3.new(4e5, 4e5, 4e5)
    bg.P = 3e3
    bg.Parent = hrp

    connection = RunService.RenderStepped:Connect(function(dt)
        if not hrp or not camera then return end

        -- اتجاهات بالنسبة للكاميرا
        local camCFrame = camera.CFrame
        local forward = camCFrame.LookVector
        local right = camCFrame.RightVector

        -- حركة أفقية حسب WASD (moveVector) + حركة رأسية (vertical)
        local desiredDir = (right * moveVector.X) + (forward * -moveVector.Z)
        -- نجعل المحور Y للصعود مستقل
        local vel = desiredDir.Unit * speed
        if desiredDir.Magnitude == 0 then vel = Vector3.new(0,0,0) end

        -- دمج الحركة الرأسية
        local vy = 0
        if vertical ~= 0 then
            vy = vertical * ascendSpeed
        end

        -- نطابق السرعة بالنسبة لاتجاه الكاميرا
        local worldVel = (vel * (1)) + Vector3.new(0, vy, 0)
        -- نعطي BodyVelocity السرعة
        bv.Velocity = worldVel

        -- ضبط الواجهة (نطبق جزء بسيط لالتفاف الجسم ليطابق الكاميرا)
        local look = Vector3.new(camCFrame.LookVector.X, 0, camCFrame.LookVector.Z)
        if look.Magnitude > 0 then
            bg.CFrame = CFrame.new(hrp.Position, hrp.Position + look)
        end
    end)
end

local function disableFly()
    flyEnabled = false
    if connection then connection:Disconnect(); connection = nil end
    if bv then bv:Destroy(); bv = nil end
    if bg then bg:Destroy(); bg = nil end
    if humanoid then
        pcall(function() humanoid.PlatformStand = false end)
    end
end

-- تغيير سرعة الطيران - اختياري
local function setSpeed(newSpeed)
    speed = math.clamp(newSpeed, 10, 500)
end

-- إدارة مدخلات لوحة المفاتيح
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if not character then return end
    if input.UserInputType == Enum.UserInputType.Keyboard then
        local key = input.KeyCode
        if key == Enum.KeyCode.E then
            -- تبديل الطيران
            if flyEnabled then
                disableFly()
            else
                enableFly()
            end
        elseif key == Enum.KeyCode.W then
            moveVector = Vector3.new(moveVector.X, moveVector.Y, -1)
        elseif key == Enum.KeyCode.S then
            moveVector = Vector3.new(moveVector.X, moveVector.Y, 1)
        elseif key == Enum.KeyCode.A then
            moveVector = Vector3.new(-1, moveVector.Y, moveVector.Z)
        elseif key == Enum.KeyCode.D then
            moveVector = Vector3.new(1, moveVector.Y, moveVector.Z)
        elseif key == Enum.KeyCode.Space then
            vertical = 1
        elseif key == Enum.KeyCode.LeftControl or key == Enum.KeyCode.LeftShift then
            vertical = -1
        end
    end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if not character then return end
    if input.UserInputType == Enum.UserInputType.Keyboard then
        local key = input.KeyCode
        if key == Enum.KeyCode.W then
            moveVector = Vector3.new(moveVector.X, moveVector.Y, 0)
        elseif key == Enum.KeyCode.S then
            moveVector = Vector3.new(moveVector.X, moveVector.Y, 0)
        elseif key == Enum.KeyCode.A then
            moveVector = Vector3.new(0, moveVector.Y, moveVector.Z)
        elseif key == Enum.KeyCode.D then
            moveVector = Vector3.new(0, moveVector.Y, moveVector.Z)
        elseif key == Enum.KeyCode.Space then
            if vertical == 1 then vertical = 0 end
        elseif key == Enum.KeyCode.LeftControl or key == Enum.KeyCode.LeftShift then
            if vertical == -1 then vertical = 0 end
        end
    end
end)

-- تنظيف عند خروج اللاعب أو موت الشخصية
player.AncestryChanged:Connect(function()
    if not player:IsDescendantOf(game) then
        disableFly()
    end
end)

-- لو أردت ضبط سرعة مؤقتة أو واجهة لتغييرها، استدعِ setSpeed(newValue)
