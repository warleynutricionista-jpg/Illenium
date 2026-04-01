fx_version "cerulean"
creator 'loris29p, sertinox'
lua54 'yes'
games {
  "gta5"
}

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
  'oxmysql',
}

exports {
  'IsPedFreemode',
  'IsMale',
  'IsFemale',
  'GetSex',
  'IsModelExist',
  'GetSkin',
  'SetSkin',
  'ChangeClothes',
  'GetOverlays',
  'SetComponentById',
  'SetPropById',
  'GetComponentById',
  'GetPropById',
  'SetPlayerModel'
}

escrow_ignore {
  'shared/*',
  'locales/*',
  'bridge/*',
}