Config = {
    MaxCharacters = 5,
    LockedSlots = {2, 3, 4, 5},
    LockTheSlots = true,
    RandomPeds = {
        'mp_m_freemode_01',
        'mp_f_freemode_01',
    },
    SkinMenus = {
        ['qb-appearance'] = {},
    },
    AppearanceConfig = {
        ped = true, headBlend = true, faceFeatures = true, headOverlays = true, components = true, componentConfig = { masks = true, upperBody = true, lowerBody = true, bags = true, shoes = true, scarfAndChains = true, bodyArmor = true, shirts = true, decals = true, jackets = true }, props = true, propConfig = { hats = true, glasses = true, ear = true, watches = true, bracelets = true }, tattoos = true, enableExit = true,
    },
    SkinSupport = {
        ['qb-appearance'] = true
    },
    PedCoords = vector4(-1002.052734, -1503.903320, 4.572144, 116.22),
    HiddenCoords = vector4(-1002.052734, -1510.903320, 4.572144, 116.22),
    DefaultSpawn = vector4(-1035.7698974609, -2738.8845214844, 20.169267654419, 334.97),
    RandomPedAnimations = {
        [1] = {
            type = 'sceneario',
            anim = 'WORLD_HUMAN_AA_COFFEE',
        },
        [2] = {
            type = 'sceneario',
            anim = 'WORLD_HUMAN_AA_SMOKE',
        },
        [3] = {
            type = 'anim',
            anim = 'anim@amb@nightclub@peds@',
            dict = 'rcmme_amanda1_stand_loop_cop',
        },
    },
    SpawnLocations = {
        [1] = {
            title = 'Mirror Park',
            description = 'Mirror park boulevard is home to a very fun and different environment.',
            coords = vector4(1127.14, -645.29, 55.79, 281.89),
        },
        [2] = {
            title = 'Beach',
            description = 'A walk on the unique beach by Aguja St. is a good nights rest.',
            coords = vector4(412.285, -976.30, 29.41, 90.0),
        },
        [3] = {
            title = 'Sandy Shores',
            description = 'It will be interesting to experience Route 68 and its surroundings, one of the most famous roads in Los Angeles County.',
            coords = vector4(277.9, -578.51, 43.12, 129.61),
        },
        [4] = {
            title = 'Paleto Bay',
            description = 'Located at the top of the city, it is one of the rare regions that host the rare beauties of nature.',
            coords = vector4(-177.94, 6212.09, 31.22, 298.54),
        },
        [5] = {
            title = 'Motel',
            description = 'The motel is a good place for you to have fun and socialize.',
            coords = vector4(-177.94, 6212.09, 31.22, 298.54),
        },
    },
}

Config.Skin = 'qb-appearance'
Config.SkinMenu = {}

local skincount = {}

for skin, _ in pairs(Config.SkinSupport) do
	if GetResourceState(skin) == 'started' or GetResourceState(skin) == 'starting' then
		Config.Skin = skin
		table.insert(skincount, skin)
	end
end

for resource, v in pairs(Config.SkinMenus) do
	if resource == Config.Skin then
		for v in pairs(v) do
			if v.use then
				Config.SkinMenu[resource] = {event = v.event or false, exports = v.exports or false}
			end
		end
	end
end