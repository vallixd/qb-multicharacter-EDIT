fx_version 'bodacious'
game 'gta5'
lua54 'yes'
author 'VL'

client_scripts {
    'config.lua',
    'locale.lua',
    'client/client_editable.lua',
    'client/client.lua',
    'default_skin.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'config.lua',
    'server/server_editable.lua',
    'server/server.lua',
    'default_skin.lua'
}

ui_page 'nui/index.html'

files {
    'nui/*.*',
    'nui/assets/*.*',
}