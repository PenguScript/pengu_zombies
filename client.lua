
Zombies = {}


RegisterNetEvent("zombies:despawnZombie", function(zombie)
	while NetworkGetEntityFromNetworkId(zombie) == 0 do
		Wait(1)
	end
	local zombie = NetworkGetEntityFromNetworkId(zombie)
	for i,v in pairs(Zombies) do
		if v == zombie then
			table.remove(Zombies, i)
		end
		Wait(10)
	end
end)
local QBCore = exports['qb-core']:GetCoreObject()

if Config.Callbacks == "ox" then
	lib.callback.register("zombies:getPlayerStatus", function()
		if QBCore.Functions.GetPlayerData() then
			return true
		end
		return false
	end)

	lib.callback.register("zombies:getGroundZ", function(x, y, z)
		local onGround, value = GetGroundZFor_3dCoord(x, y, z, true)
		return value
	end)
elseif Config.Callbacks == "qb" then
	QBCore.Functions.CreateCallback("zombies:getPlayerStatus", function(source, cb)
		if QBCore.Functions.GetPlayerData() then
			cb(true)
		end
		cb(false)
	end)
	QBCore.Functions.CreateCallback("zombies:getGroundZ", function(source, cb, x, y, z)
		local onGround, value = GetGroundZFor_3dCoord(x, y, z, true)
		cb(value)
	end)
end

local DamageQueue = {}

local function existsInTable(data)
	for i,v in pairs(DamageQueue) do
		if v == data then
			return true
		end
	end
	return false
end

local function DamagePlayer(zombie)
	if not existsInTable(zombie) then
		local index = #DamageQueue+1
		DamageQueue[index] = zombie
		ApplyDamageToPed(cache.ped, 5, true)
		Wait(2500)
		table.remove(DamageQueue, index)
		return true	
	else
		return false
	end
end

RegisterNetEvent('zombies:setupZombie', function(Zombie)
	while NetworkGetEntityFromNetworkId(Zombie) == 0 do
		Wait(1)
	end
	local Zombie = NetworkGetEntityFromNetworkId(Zombie)
	Zombies[#Zombies+1] = Zombie
	if not DecorExistOn(Zombie, 'RegisterZombie') then
		ClearPedTasks(Zombie)
		ClearPedSecondaryTask(Zombie)
		ClearPedTasksImmediately(Zombie)
		local ZombiePosition = GetEntityCoords(Zombie)
		TaskWanderInArea(Zombie, ZombiePosition.x, ZombiePosition.y, ZombiePosition.z, 40.0, 2, 1000)		
		SetPedRelationshipGroupHash(Zombie, 'ZOMBIE')
		ApplyPedDamagePack(Zombie, 'BigHitByVehicle', 0.0, 1.0)
		SetEntityHealth(Zombie, 200)

		RequestAnimSet('move_m@drunk@verydrunk')
		while not HasAnimSetLoaded('move_m@drunk@verydrunk') do
			Citizen.Wait(0)
		end
		SetPedMovementClipset(Zombie, 'move_m@drunk@verydrunk', 1.0)

		SetPedConfigFlag(Zombie, 100, false)
		DecorSetBool(Zombie, 'RegisterZombie', true)
	end

	SetPedRagdollBlockingFlags(Zombie, 1)
	SetPedCanRagdollFromPlayerImpact(Zombie, false)
	SetPedSuffersCriticalHits(Zombie, true)
	SetPedEnableWeaponBlocking(Zombie, true)
	DisablePedPainAudio(Zombie, true)
	StopPedSpeaking(Zombie, true)
	SetPedDiesWhenInjured(Zombie, false)
	StopPedRingtone(Zombie)
	SetPedMute(Zombie)
	SetPedIsDrunk(Zombie, true)
	SetPedConfigFlag(Zombie, 166, false)
	SetPedConfigFlag(Zombie, 170, false)
	SetBlockingOfNonTemporaryEvents(Zombie, true)
	SetPedCanEvasiveDive(Zombie, false)
	RemoveAllPedWeapons(Zombie, true)

end)

RegisterNetEvent('zombies:triggerAttackAnimation', function(entity)
	while NetworkGetEntityFromNetworkId(entity) == 0 do
		Wait(1)
	end
	local entity = NetworkGetEntityFromNetworkId(entity)

	RequestAnimSet('melee@unarmed@streamed_core_fps')
	while not HasAnimSetLoaded('melee@unarmed@streamed_core_fps') do
		Wait(1)
	end

	TaskPlayAnim(entity, 'melee@unarmed@streamed_core_fps', 'ground_attack_0_psycho', 8.0, 1.0,
		-1, 48, 0.001, false, false, false)
end)

Shooting = false
Sneaking = false
Driving = false
Running = false

local function setWander(v)
	CreateThread(function ()
		
		ClearPedTasks(v)
		local lastCoords = GetEntityCoords(PlayerPedId())
		local onGround, groundZ = GetGroundZFor_3dCoord(lastCoords.x, lastCoords.y, lastCoords.z, true)
		lastCoords = vector3(lastCoords.x, lastCoords.y, groundZ)
		TaskFollowNavMeshToCoord(v, lastCoords.x, lastCoords.y, lastCoords.z, 1.0, -1, 2.0, 1, GetEntityHeading(PlayerPedId()))
		local lastZombieCoord = vector3(0,0,0)
		while #(lastCoords-GetEntityCoords(v)) > 5.0 do
			local currentZombieCoord = GetEntityCoords(v)
			if currentZombieCoord == lastZombieCoord then
				break
			end
			Wait(100)
		end
		print('wander')

		TaskWanderInArea(v, lastCoords.x, lastCoords.y, lastCoords.z, 40.0, 2, 1000)		
	end)
end

local function shouldChasePlayer(v, dist)
	if IsPedDeadOrDying(v, false) then return end
	local following = GetScriptTaskStatus(v, "SCRIPT_TASK_FOLLOW_TO_OFFSET_OF_ENTITY")
	print(following)
	if tostring(following) ~= "1" then
		if dist < 3.0 and Sneaking then
			TaskFollowToOffsetOfEntity(v, PlayerPedId(), 0.0,0.0,0.0,1.5, 10.0, 1, true)
		elseif dist < 25.0 and Running then
			TaskFollowToOffsetOfEntity(v, PlayerPedId(), 0.0,0.0,0.0,1.5, 10.0, 1, true)
		elseif dist < 100.0 and Driving then
			TaskFollowToOffsetOfEntity(v, PlayerPedId(), 0.0,0.0,0.0,1.5, 10.0, 1, true)
		elseif dist < 140.0 and Shooting then
			TaskFollowToOffsetOfEntity(v, PlayerPedId(), 0.0,0.0,0.0,1.5, 10.0, 1, true)
		elseif dist < 15.0 then
			TaskFollowToOffsetOfEntity(v, PlayerPedId(), 0.0,0.0,0.0,1.5, 10.0, 1, true)
		end
	else
		print(Shooting)
		if dist > 140.0 and Shooting then
			setWander(v)
		elseif dist > 100.0 and Driving and not Shooting then
			setWander(v)
		elseif dist > 25.0 and Running and not Driving or Shooting then
			setWander(v)
		elseif dist > 25.0 and not Driving or Shooting then
			setWander(v)
		end
	end
end

local function setStatus(type, state)
	if type == "Shooting" then
		if not Shooting then
			Shooting = true
			Wait(3000)
			Shooting = false
		end
	elseif type == "Sneaking" then
		Sneaking = state
	elseif type == "Driving" then
		Driving = state
	elseif type == "Running" then
		Running = state
	end
end

CreateThread(function()
	while true do
		local coords = GetEntityCoords(PlayerPedId())
		for i,v in pairs(Zombies) do
			local zombieCoords = GetEntityCoords(v)
			local dist = #(coords.xyz-zombieCoords.xyz)
				if dist < Config.AttackDist then
					if not IsPedRagdoll(v) and not IsPedGettingUp(v) then
						while NetworkGetNetworkIdFromEntity(v) == 0 do
							Wait(1)
						end
						TriggerServerEvent("zombies:requestAttackAnimation", NetworkGetNetworkIdFromEntity(v))
						DamagePlayer(v)
					end
				end
				shouldChasePlayer(v, dist)
		end
		Wait(100)
	end
end)

CreateThread(function()
	while true do
		local ped = PlayerPedId()
		if IsPedShooting(ped) then
			setStatus("Shooting", true)
		end
		if GetPedStealthMovement(ped) then
			setStatus("Sneaking", true)
		else
			setStatus("Sneaking", false)
		end
		if IsPedRunning(ped) then
			setStatus("Running", true)
		else
			setStatus("Running", false)
		end
		if IsPedSittingInAnyVehicle(ped) then
			if GetIsVehicleEngineRunning(GetVehiclePedIsIn(ped, false)) then
				setStatus("Driving", true)
			else
				setStatus("Driving", false)
			end
		else
			Driving = false
		end
		Wait(1)
	end
end)


AddEventHandler('gameEventTriggered', function(name, args)
	if name == "CEventNetworkEntityDamage" then
		if args[6] == 1 then
            if IsEntityAPed(args[1]) then
				if args[2] == GetPlayerPed(-1) then
					TriggerServerEvent("zombies:zombieKilled", NetworkGetNetworkIdFromEntity(args[1]))
				end
            end
        end
	end
end)

local busy = false
RegisterNetEvent('zombies:syncLootable', function(entity, reward, amount)
	exports.ox_target:addEntity(entity, {
        {
            label = "Loot Zombie",
            icon = "fas fa-box",
            onSelect = function()
				if not busy then
					busy = true
					if Config.Progressbar == "ox" then
						if lib.progressCircle({
							label = "Checking Zombie for Loot",
							duration = 2000,
							position = "bottom",
							disable = {
								move = true,
								combat = true,
							},
							anim = {
								dict = "random@domestic",
								clip = "pickup_low",
								flag = 0,
							}
						}) then
							if reward then
								local looted = lib.callback.await("zombies:rewardLoot", false, entity, reward, amount)
							else
								lib.notify({label = "No loot found", type = "error", duration = 4000, description = "Keep looking!"})
							end
							local delete = lib.callback.await("zombies:deleteZombie", false, entity)
						end
					elseif Config.Progressbar == "qb" then
						QBCore.Functions.Progressbar('name', 'Checking Zombie for Loot', 2000, false, true, {
							disableMovement = true,
							disableCarMovement = true,
							disableMouse = false,
							disableCombat = true,
						}, {
							animDict = 'random@domestic',
							anim = 'pickup_low',
							flags = 0,
						}, {}, {}, function()
							if reward then
								local looted = QBCore.Functions.TriggerCallback("zombies:rewardLoot", entity, reward, amount)
							else
								QBCore.Functions.Notify("No loot found", "error")
							end
							local delete = QBCore.Functions.TriggerCallback("zombies:deleteZombie", entity)
						end, function()
							
						end)
					end
					busy = false
				end
            end
        }
    })
end)


SetRandomEventFlag(false)

local scenarios = {
  'WORLD_VEHICLE_ATTRACTOR',
  'WORLD_VEHICLE_AMBULANCE',
  'WORLD_VEHICLE_BICYCLE_BMX',
  'WORLD_VEHICLE_BICYCLE_BMX_BALLAS',
  'WORLD_VEHICLE_BICYCLE_BMX_FAMILY',
  'WORLD_VEHICLE_BICYCLE_BMX_HARMONY',
  'WORLD_VEHICLE_BICYCLE_BMX_VAGOS',
  'WORLD_VEHICLE_BICYCLE_MOUNTAIN',
  'WORLD_VEHICLE_BICYCLE_ROAD',
  'WORLD_VEHICLE_BIKE_OFF_ROAD_RACE',
  'WORLD_VEHICLE_BIKER',
  'WORLD_VEHICLE_BOAT_IDLE',
  'WORLD_VEHICLE_BOAT_IDLE_ALAMO',
  'WORLD_VEHICLE_BOAT_IDLE_MARQUIS',
  'WORLD_VEHICLE_BOAT_IDLE_MARQUIS',
  'WORLD_VEHICLE_BROKEN_DOWN',
  'WORLD_VEHICLE_BUSINESSMEN',
  'WORLD_VEHICLE_HELI_LIFEGUARD',
  'WORLD_VEHICLE_CLUCKIN_BELL_TRAILER',
  'WORLD_VEHICLE_CONSTRUCTION_SOLO',
  'WORLD_VEHICLE_CONSTRUCTION_PASSENGERS',
  'WORLD_VEHICLE_DRIVE_PASSENGERS',
  'WORLD_VEHICLE_DRIVE_PASSENGERS_LIMITED',
  'WORLD_VEHICLE_DRIVE_SOLO',
  'WORLD_VEHICLE_FIRE_TRUCK',
  'WORLD_VEHICLE_EMPTY',
  'WORLD_VEHICLE_MARIACHI',
  'WORLD_VEHICLE_MECHANIC',
  'WORLD_VEHICLE_MILITARY_PLANES_BIG',
  'WORLD_VEHICLE_MILITARY_PLANES_SMALL',
  'WORLD_VEHICLE_PARK_PARALLEL',
  'WORLD_VEHICLE_PARK_PERPENDICULAR_NOSE_IN',
  'WORLD_VEHICLE_PASSENGER_EXIT',
  'WORLD_VEHICLE_POLICE_BIKE',
  'WORLD_VEHICLE_POLICE_CAR',
  'WORLD_VEHICLE_POLICE',
  'WORLD_VEHICLE_POLICE_NEXT_TO_CAR',
  'WORLD_VEHICLE_QUARRY',
  'WORLD_VEHICLE_SALTON',
  'WORLD_VEHICLE_SALTON_DIRT_BIKE',
  'WORLD_VEHICLE_SECURITY_CAR',
  'WORLD_VEHICLE_STREETRACE',
  'WORLD_VEHICLE_TOURBUS',
  'WORLD_VEHICLE_TOURIST',
  'WORLD_VEHICLE_TANDL',
  'WORLD_VEHICLE_TRACTOR',
  'WORLD_VEHICLE_TRACTOR_BEACH',
  'WORLD_VEHICLE_TRUCK_LOGS',
  'WORLD_VEHICLE_TRUCKS_TRAILERS',
  'WORLD_VEHICLE_DISTANT_EMPTY_GROUND'
}

CreateThread(function()
  for i, v in ipairs(scenarios) do SetScenarioTypeEnabled(v, false) end
  for i = 1, 15 do EnableDispatchService(i, false) end

  SetRandomBoats(false)
  SetGarbageTrucks(false)
  SetRandomTrains(false)
  SetCreateRandomCops(false)
  SetCreateRandomCopsOnScenarios(false)
  SetCreateRandomCopsNotOnScenarios(false)
  SetDispatchCopsForPlayer(PlayerId(), false)
  SetPedPopulationBudget(0.0)
  SetNumberOfParkedVehicles(0.0)
  SetVehiclePopulationBudget(0.0)
  DistantCopCarSirens(false)
  DisableVehicleDistantlights(true) -- fixes distant ghost cars from appearing
  SetArtificialLightsState(true)
  SetArtificialLightsStateAffectsVehicles(false)
end)