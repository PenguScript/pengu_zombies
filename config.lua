Config = {}

Config.ChanceForLootableSpawn = 25 -- chance out of 100 for a lootable to spawn
Config.PurgeDistance = 150.0 -- distance for zombies to cleanup

Config.Callbacks = "ox" -- ox or qb
Config.Progressbar = "ox" -- ox or qb


Config.SpawnRadius = 140.0 -- radius around you that zombies spawn in
Config.PerPlayerCap = 10 -- the amount of zombies that spawn per player


Config.AttackDist = 1.25 -- distance from player when zombies begin to attack


Shooting = false
Running = false
Sneaking = false
Driving = false

SafeZones = {
    { x = 450.5966,  y = -998.9636, z = 28.4284, radius = 80.0 }, -- Mission Row
    { x = 1853.6666, y = 3688.0222, z = 33.2777, radius = 40.0 }, -- Sandy Shores
    { x = -104.1444, y = 6469.3888, z = 30.6333, radius = 60.0 } -- Paleto Bay
}

Config.Density = 15
Config.SpawnDist = 60.0

Config.Bosses = {
    {
        coords = vec4(1641.16, 1211.91, 85.14, 162.47),
        zoneRadius = 50.0,


        model = "a_m_m_salton_02",
        health = 500.0,
        speed = 2.2,
        spawned = nil,
    }
}

Config.MinSleep, Config.MaxSleep = 5000, 10000

Config.PedTypes = {
    "u_m_m_prolsec_01",
    "a_m_m_hillbilly_01",
    "a_m_m_polynesian_01",
    "a_m_m_skidrow_01",
    "a_m_m_salton_02",
    "a_m_m_fatlatin_01",
    "a_m_m_beach_01",
    "a_m_m_farmer_01",
    "a_m_m_malibu_01",
    "a_m_m_rurmeth_01",
    "a_m_y_salton_01",
    "a_m_m_skater_01",
    "a_m_m_tennis_01",
    "a_m_o_acult_02",
    "a_m_y_genstreet_01",
    "a_m_y_genstreet_02",
    "a_m_y_methhead_01",
    "a_m_y_stlat_01",
    "s_m_m_paramedic_01",
    "s_m_y_cop_01",
    "s_m_y_prismuscl_01",
    "s_m_y_prisoner_01",
    "a_m_m_og_boss_01",
    "a_m_m_eastsa_02",
    "a_f_y_juggalo_01",
}

Config.LootTable = {
    ["common"] = {
        { name = "ammo-9", chance = 20, amount = { 10, 20 } }, -- Amount range from 10 to 20
        -- Add more common loot items here
    },
    ["rare"] = {
        { name = "weapon_assaultrifle", chance = 20, amount = 1 }, -- Amount range from 10 to 20
    },
    ["epic"] = {
        { name = "weapon_pistol", chance = 20, amount = 1 }, -- Amount range from 10 to 20
    },
    -- Add more loot qualities as needed
}
