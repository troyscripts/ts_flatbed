fx_version 'cerulean'
game 'gta5'
author 'TroyScripts'
description 'Vaste laadbak met oprijplaten, geleide lier en voertuigtransport'
version '0.1.1-beta'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
    'shared/math.lua',
    'shared/bridge.lua'
}
client_scripts { 'client/main.lua', 'client/wheellift.lua' }
server_scripts { 'server/main.lua' }
dependencies { 'ts_bridge', 'ox_lib', 'ox_target', '/onesync' }
