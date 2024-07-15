fx_version 'cerulean'
games { 'gta5' }

author 'PenguScripts'
description 'pengu_zombies'
version '1.0.0'

client_scripts {
    'client.lua',
    'ped_name.lua'
}

server_script 'server.lua'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
}

files {
    'peds.meta',
}

data_file 'PED_METADATA_FILE' 'peds.meta'


lua54 'yes'