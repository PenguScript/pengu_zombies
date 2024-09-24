SpawnedZombies = {}
Cooldowns = {}
local QBCore = exports['qb-core']:GetCoreObject()

local function zombieExists(entity, source)
    for i, v in pairs(SpawnedZombies[tostring(source)]) do
        if v == NetworkGetEntityFromNetworkId(entity) then
            return true, i
        end
    end
    return false, nil
end


local function despawnZombie(zombie)
    DeleteEntity(zombie)
    TriggerClientEvent("zombies:despawnZombie", -1, NetworkGetNetworkIdFromEntity(zombie))
end

if Config.Callbacks == "ox" then
    lib.callback.register("zombies:deleteZombie", function(source, entity)
        while NetworkGetEntityFromNetworkId(entity) == 0 do
            Wait(1)
        end
        local svEntity = NetworkGetEntityFromNetworkId(entity)
        for i,v in pairs(SpawnedZombies[tostring(source)]) do
            if v == svEntity then
                table.remove(SpawnedZombies[tostring(source)], i)
                despawnZombie(svEntity)
            end
        end
    end)
elseif Config.Callbacks == "qb" then
    QBCore.Functions.CreateCallback("zombies:deleteZombie", function(source, cb, entity)
        while NetworkGetEntityFromNetworkId(entity) == 0 do
            Wait(1)
        end
        local svEntity = NetworkGetEntityFromNetworkId(entity)
        for i,v in pairs(SpawnedZombies[tostring(source)]) do
            if v == svEntity then
                table.remove(SpawnedZombies[tostring(source)], i)
                despawnZombie(svEntity)
            end
        end
    end)
end

local function spawnZombie(source)
    local ped = GetPlayerPed(source)
    local coords = GetEntityCoords(ped)
    local angle = math.rad(math.random(0, 360))
    
    local distance = math.random(50, Config.SpawnRadius)
    
    local offsetX = distance * math.cos(angle)
    local offsetY = distance * math.sin(angle)
    
    local groundZ
    if Config.Callbacks == "ox" then
        groundZ = lib.callback.await("zombies:getGroundZ", source, coords.x + offsetX, coords.y + offsetY, coords.z)
    elseif Config.Callbacks == "qb" then
        QBCore.Functions.TriggerCallback('zombies:getGroundZ', source, function(result)
            groundZ = result
        end, coords.x + offsetX, coords.y + offsetY, coords.z)
    end
    if groundZ == 0.0 then return end
    local spawnCoords = vector3(coords.x + offsetX, coords.y + offsetY, groundZ)

    local ped = CreatePed(0, Config.PedTypes[math.random(#Config.PedTypes)], spawnCoords.x, spawnCoords.y, spawnCoords.z, math.random(0, 360), true, false)
    while NetworkGetNetworkIdFromEntity(ped) == 0 do
        Wait(1)
    end
    SpawnedZombies[source][#SpawnedZombies[source]+1] = ped
    TriggerClientEvent("zombies:setupZombie", -1, NetworkGetNetworkIdFromEntity(ped))
end

RegisterNetEvent("zombies:requestAttackAnimation", function(entity)
    TriggerClientEvent("zombies:triggerAttackAnimation", -1, entity)
end)

AddEventHandler('onResourceStop', function(resource)
   if resource == GetCurrentResourceName() then
      for i,v in pairs(SpawnedZombies) do
        for i,v in pairs(v) do
            DeleteEntity(v)
        end
      end
   end
end)

if Config.Callbacks == "ox" then
    lib.callback.register("zombies:rewardLoot", function(source, entity, reward, amount)
        print(entity)
        while NetworkGetEntityFromNetworkId(entity) == 0 do
            Wait(1)
        end
        local svEntity = NetworkGetEntityFromNetworkId(entity)

        local pass, index = zombieExists(entity, source)
        print(pass)
        if pass then
            print('lol')
            if exports.ox_inventory:CanCarryItem(source, reward, amount) then
                exports.ox_inventory:AddItem(source, reward, amount)
                return true
            else
                exports.ox_inventory:CustomDrop('Zombie Loot', {
                    { reward, amount },
                }, GetEntityCoords(svEntity), 1)
                return true
            end
        end
    end)
elseif Config.Callbacks == "qb" then
    QBCore.Functions.CreateCallback("zombies:rewardLoot", function(source, cb, entity, reward, amount)
        print(entity)
        while NetworkGetEntityFromNetworkId(entity) == 0 do
            Wait(1)
        end
        local svEntity = NetworkGetEntityFromNetworkId(entity)

        local pass, index = zombieExists(entity, source)
        print(pass)
        if pass then
            print('lol')
            if exports['qb-inventory']:CanAddItem(source, reward, amount) then
                exports['qb-inventory']:AddItem(source, reward, amount)
                cb(true)
            end
        end
    end)
end

local function selectLootQuality()
    local totalWeight = 0
    local qualityWeights = {}

    for quality, lootList in pairs(Config.LootTable) do
        for _, loot in ipairs(lootList) do
            totalWeight = totalWeight + (loot.chance or 0)
        end
        qualityWeights[quality] = totalWeight
    end

    local randomNum = math.random(1, totalWeight)

    local selectedQuality
    for quality, weight in pairs(qualityWeights) do
        if randomNum <= weight then
            selectedQuality = quality
            break
        end
    end

    return selectedQuality
end


local function selectLootItem(quality)
    local lootList = Config.LootTable[quality]

    if lootList then
        local totalWeight = 0

        for _, loot in ipairs(lootList) do
            totalWeight = totalWeight + (loot.chance or 0)
        end

        local randomNum = math.random(1, totalWeight)

        for _, loot in ipairs(lootList) do
            if randomNum <= (loot.chance or 0) then
                local amount = loot.amount
                if type(amount) == "table" then
                    amount = math.random(amount[1], amount[2])
                end
                return loot.name, amount
            else
                randomNum = randomNum - (loot.chance or 0)
            end
        end
    end

    return nil, 0
end

local function dropLoot()
    local quality = selectLootQuality()
    local lootItem, amount = selectLootItem(quality)

    return lootItem, amount
end

local function LootableSpawn(entity, loot)
    local reward = nil
    local amount = 0
    if loot then
        reward, amount = dropLoot()
    end
    print(reward)
    print(amount)
    TriggerClientEvent("zombies:syncLootable", -1, entity, reward, amount)
end

RegisterNetEvent("zombies:zombieKilled", function(entity)
    print(source)
    local exists, index = zombieExists(entity, source)
    if exists then
        print("killed a zombie!!!!!!")
        local chance = math.random(100)
        if chance < Config.ChanceForLootableSpawn then
            LootableSpawn(entity, true)
        else
            LootableSpawn(entity, false)
        end
    else
        print(source .. " killed an entity, however it was not a zombie.")
    end
end)


local function attemptPurgeZombies(source)
    local playerCoords = GetEntityCoords(GetPlayerPed(source))
    for i,v in pairs(SpawnedZombies[source]) do
        local v = v
        local zombieCoords = GetEntityCoords(v)
        if #(playerCoords.xyz-zombieCoords.xyz) > Config.PurgeDistance then
            local toPurge = true
            for _,plr in pairs(GetPlayers()) do
                if #(GetEntityCoords(plr).xyz-zombieCoords.xyz) < Config.PurgeDistance then
                    -- Within dist - should switch table indexes
                    table.remove(SpawnedZombies[source], i)
                    table.insert(SpawnedZombies[plr], v)
                    toPurge = false
                    break
                end
            end
            if toPurge then
               -- needs to purge
               print(json.encode(SpawnedZombies[source]))
               print(i)
               table.remove(SpawnedZombies[source], i)
               despawnZombie(v)
               print('despawned zombie')
            end
            break
        end
    end
end


CreateThread(function()
    while true do
        local players = GetPlayers()
        if players then
            for i,v in pairs(players) do
                if not SpawnedZombies[v] then SpawnedZombies[v] = {} end
                local status = false
                if Config.Callbacks == "ox" then
                    status = lib.callback.await("zombies:getPlayerStatus", v)
                elseif Config.Callbacks == "qb" then
                    QBCore.Functions.TriggerCallback('zombies:getPlayerStatus', v, function(result)
                        status = result
                    end)
                end
                if status then
                    if #SpawnedZombies[v] < Config.PerPlayerCap then
                        spawnZombie(v)
                    else
                        attemptPurgeZombies(v)
                    end
                end
            end
        end

        Wait(math.random(Config.MinSleep, Config.MaxSleep))
    end
end)
