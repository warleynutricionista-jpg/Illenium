fx_version "cerulean"
lua54 'yes'
games { "gta5" }

name 'kIdentity'
version '1.0.0'

ui_page 'web/build/index.html'

shared_scripts {
    'locales/*.lua',
    'shared/sh_*.lua',
    'bridge/loader.lua'
}

client_scripts {
    'bridge/client.lua',
    'client/**/*'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'bridge/server.lua',
    'server/**/*'
}

files {
    'web/build/index.html',
    'web/build/**/*'
}

dependencies {
    'oxmysql'
}

exports {
    'OpenIdentityForm',
    'CloseIdentityForm',
    'IsIdentityOpen'
}

server_exports {
    'GetPlayerIdentity',
    'HasPlayerIdentity'
}
