local noclip = false
local invisible = false
local baseSpeed = 1.0
local speed = baseSpeed
local followCamera = true
local shiftSpeedMultiplier = 4.0 -- مضاعف السرعة عند الضغط على Shift

-- دالة لتبديل النوكليب + الاختفاء
function toggleNoclip()
    local playerPed = PlayerPedId()
    noclip = not noclip
    invisible = noclip  -- تزامن حالة الاختفاء مع النوكليب

    SetEntityInvincible(playerPed, noclip)
    SetEntityCollision(playerPed, not noclip, not noclip)

    if noclip then
        -- تفعيل الاختفاء
        SetEntityVisible(playerPed, false, false)
        SetEntityAlpha(playerPed, 0, false)
        print("🚀 تم تفعيل النوكليب + الاختفاء")
    else
        -- إلغاء الاختفاء
        SetEntityVisible(playerPed, true, false)
        ResetEntityAlpha(playerPed)
        SetEntityInvincible(playerPed, false)
        print("👀 تم إلغاء النوكليب + العودة للوضع الطبيعي")
    end
end

-- دوال المساعدة
local function vec3Length(v)
    return math.sqrt(v.x * v.x + v.y * v.y + v.z * v.z)
end

local function normalizeVec3(v)
    local len = vec3Length(v)
    if len == 0 then return vector3(0.0, 0.0, 0.0) end
    return vector3(v.x / len, v.y / len, v.z / len)
end

local function getCamVectors()
    local camRot = GetGameplayCamRot(2)
    local rz = math.rad(camRot.z)
    local rx = math.rad(camRot.x)

    local forward = vector3(-math.sin(rz) * math.cos(rx), math.cos(rz) * math.cos(rx), math.sin(rx))
    local right = vector3(forward.y, -forward.x, 0.0)
    right = normalizeVec3(right)
    forward = normalizeVec3(forward)
    local up = vector3(0.0, 0.0, 1.0)
    return forward, right, up
end

function noclipMovement()
    if not noclip then return end

    local playerPed = PlayerPedId()
    local pos = GetEntityCoords(playerPed, false)
    if not pos then return end

    local forward, right, up = getCamVectors()
    local move = vector3(0.0, 0.0, 0.0)

    if IsControlPressed(0, 32) then move = move + forward end -- W
    if IsControlPressed(0, 33) then move = move - forward end -- S
    if IsControlPressed(0, 34) then move = move - right end   -- A
    if IsControlPressed(0, 35) then move = move + right end   -- D
    if IsControlPressed(0, 44) then move = move - up end      -- Q (نزول)
    if IsControlPressed(0, 38) then move = move + up end      -- E (صعود)

    local len = vec3Length(move)
    if len > 0 then
        local norm = normalizeVec3(move)
        local delta = vector3(norm.x * speed, norm.y * speed, norm.z * speed)
        pos = pos + delta
    end

    SetEntityCoordsNoOffset(playerPed, pos.x, pos.y, pos.z, true, true, true)

    local camRot = GetGameplayCamRot(2)
    SetEntityRotation(playerPed, camRot.x, 0.0, camRot.z, 2, true)
end

function stabilizeInAir()
    if noclip then
        local playerPed = PlayerPedId()
        local pos = GetEntityCoords(playerPed, false)
        SetEntityCoordsNoOffset(playerPed, pos.x, pos.y, pos.z, true, true, true)
    end
end

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)

        -- F2 لتبديل النوكليب + الاختفاء
        if IsControlJustPressed(0, 289) then
            toggleNoclip()
        end

        -- F4 لتغيير السرعة الأساسية
        if IsControlJustPressed(0, 344) then
            baseSpeed = baseSpeed + 0.5
            if baseSpeed > 5.0 then
                baseSpeed = 1.0
            end
            print("🚗 السرعة الحالية: " .. baseSpeed)
        end

        -- Shift لتسريع الحركة مؤقتاً ×4
        if IsControlPressed(0, 21) then
            speed = baseSpeed * shiftSpeedMultiplier
        else
            speed = baseSpeed
        end

        noclipMovement()
        stabilizeInAir()
    end
end)
