local function getRgbColors()
	local colors = {
		hair = {},
		makeUp = {}
	}

	for i = 0, GetNumHairColors() do
		colors.hair[i+1] = {GetPedHairRgbColor(i)}
	end

	for i = 0, GetNumMakeupColors() do
		colors.makeUp[i+1] = {GetPedMakeupRgbColor(i)}
	end

	return colors
end

local playerAppearance

local function getAppearance()
	if not playerAppearance then
		playerAppearance = client.getPedAppearance(PlayerPedId())
	end

	return playerAppearance
end
client.getAppearance = getAppearance

local function addToBlacklist(item, drawable, drawableId, blacklistSettings)
    if drawable == drawableId and item.textures then
        for i = 1, #item.textures do
            blacklistSettings.textures[#blacklistSettings.textures + 1] = item.textures[i]
        end
    end
    if not item.textures or #item.textures == 0 then
        blacklistSettings.drawables[#blacklistSettings.drawables + 1] = drawable
    end
end

local function listContains(items, item)
	for i = 1, #items do
		if items[i] == item then
			return true
		end
	end
	return false
end

local function listContainsAny(items, containedItems)
	for i = 1, #items do
		if listContains(containedItems, items[i]) then
			return true
		end
	end
	return false
end

local function filterPedModelsForPlayer(pedConfigs)
    local playerPeds = {}
	local job = client.getPlayerJob()
	local gang = client.getPlayerGang()
	local allowedAces = client.getPlayerAces()

    for i = 1, #pedConfigs do
        local config = pedConfigs[i]
        if (not config.jobs and not config.gangs and not config.aces) or (config.jobs and listContains(config.jobs, job)) or (config.gangs and listContains(config.gangs, gang)) or (config.aces and listContainsAny(config.aces, allowedAces)) then
            for j = 1, #config.peds do
                playerPeds[#playerPeds + 1] = config.peds[j]
            end
        end
    end
    return playerPeds
end

local function filterBlacklistSettings(items, drawableId)
	local blacklistSettings = {
		drawables = {},
		textures = {}
	}

	local job = client.getPlayerJob()
	local gang = client.getPlayerGang()
	local allowedAces = client.getPlayerAces()

	for i = 1, #items do
		local item = items[i]
		if (item.jobs and listContains(item.jobs, job)) or (item.gangs and listContains(item.gangs, gang)) or (item.aces and listContainsAny(item.aces, allowedAces)) then
			
		elseif item.drawables then
			for j = 0, #item.drawables do
				addToBlacklist(item, item.drawables[j], drawableId, blacklistSettings)
			end
		end
	end

	return blacklistSettings
end

local function componentBlacklistMap(gender, componentId)
	local genderSettings = client.clothingBlacklistSettings[gender].components

	if componentId == 1 then
		return genderSettings.masks
	elseif componentId == 3 then
		return genderSettings.upperBody
	elseif componentId == 4 then
		return genderSettings.lowerBody
	elseif componentId == 5 then
		return genderSettings.bags
	elseif componentId == 6 then
		return genderSettings.shoes
	elseif componentId == 7 then
		return genderSettings.scarfAndChains
	elseif componentId == 8 then
		return genderSettings.shirts
	elseif componentId == 9 then
		return genderSettings.bodyArmor
	elseif componentId == 10 then
		return genderSettings.decals
	elseif componentId == 11 then
		return genderSettings.jackets
	end

	return {}
end

local function propBlacklistMap(gender, propId)
	local genderSettings = client.clothingBlacklistSettings[gender].props

	if propId == 0 then
		return genderSettings.hats
	elseif propId == 1 then
		return genderSettings.glasses
	elseif propId == 2 then
		return genderSettings.ear
	elseif propId == 6 then
		return genderSettings.watches
	elseif propId == 7 then
		return genderSettings.bracelets
	end

	return {}
end

local function getComponentSettings(ped, componentId)
	local drawableId = GetPedDrawableVariation(ped, componentId)
	local gender = client.getPedDecorationType()

	local blacklistSettings = {
		drawables = {},
		textures = {}
	}

	if client.isPedFreemodeModel(ped) then
		blacklistSettings = filterBlacklistSettings(componentBlacklistMap(gender, componentId), drawableId)
	end

	return {
		component_id = componentId,
		drawable = {
			min = 0,
			max = GetNumberOfPedDrawableVariations(ped, componentId) - 1
		},
		texture = {
			min = 0,
			max = GetNumberOfPedTextureVariations(ped, componentId, drawableId) - 1
		},
		blacklist = blacklistSettings
	}
end
client.getComponentSettings = getComponentSettings

local function getPropSettings(ped, propId)
	local drawableId = GetPedPropIndex(ped, propId)
	local gender = client.getPedDecorationType()

	local blacklistSettings = {
		drawables = {},
		textures = {}
	}

	if client.isPedFreemodeModel(ped) then
		blacklistSettings = filterBlacklistSettings(propBlacklistMap(gender, propId), drawableId)
	end

	local settings = {
		prop_id = propId,
		drawable = {
			min = -1,
			max = GetNumberOfPedPropDrawableVariations(ped, propId) - 1
		},
		texture = {
			min = -1,
			max = GetNumberOfPedPropTextureVariations(ped, propId, drawableId) - 1
		},
		blacklist = blacklistSettings
	}
	return settings
end
client.getPropSettings = getPropSettings

local function getHairSettings(ped, hair)
	local colors = getRgbColors()
	local settings = {
		style = {
			min = 0,
			max = GetNumberOfPedDrawableVariations(ped, 2) - 1
		},
		color = {
			items = colors.hair
		},
		highlight = {
			items = colors.hair
		},
		texture = {
			min = 0,
			max = GetNumberOfPedTextureVariations(ped, 2, hair.style) - 1
		}
	}

	return settings
end
client.getHairSettings = getHairSettings

local function getAppearanceSettings()
	local playerPed = PlayerPedId()

	local ped = {
		model = {
			items = filterPedModelsForPlayer(client.pedConfig.pedConfig)
		}
	}

	local tattoos = {
		items = client.totalTattoos
	}

	local components = {}
	for i = 1, #constants.PED_COMPONENTS_IDS do
		components[i] = getComponentSettings(playerPed, constants.PED_COMPONENTS_IDS[i])
	end

	local props = {}
	for i = 1, #constants.PED_PROPS_IDS do
		props[i] = getPropSettings(playerPed, constants.PED_PROPS_IDS[i])
	end

	local headBlend = {
		shapeFirst = {
			min = 0,
			max = 45
		},
		shapeSecond = {
			min = 0,
			max = 45
		},
		shapeThird = {
			min = 0,
			max = 45
		},
		skinFirst = {
			min = 0,
			max = 45
		},
		skinSecond = {
			min = 0,
			max = 45
		},
		skinThird = {
			min = 0,
			max = 45
		},
		shapeMix = {
			min = 0,
			max = 1,
			factor = 0.1,
		},
		skinMix = {
			min = 0,
			max = 1,
			factor = 0.1,
		},
		thirdMix = {
			min = 0,
			max = 1,
			factor = 0.1,
		}
	}

	local size = #constants.FACE_FEATURES
	local faceFeatures = table.create(0, size)
	for i = 1, size do
		local feature = constants.FACE_FEATURES[i]
		faceFeatures[feature] = { min = -1, max = 1, factor = 0.1}
	end

	local colors = getRgbColors()

	local colorMap = {
		beard = colors.hair,
		eyebrows = colors.hair,
		chestHair = colors.hair,
		makeUp = colors.makeUp,
		blush = colors.makeUp,
		lipstick = colors.makeUp,
	}

	size = #constants.HEAD_OVERLAYS
	local headOverlays = table.create(0, size)

	for i = 1, size do
		local overlay = constants.HEAD_OVERLAYS[i]
		local settings = {
			style = {
				min = 0,
				max = GetPedHeadOverlayNum(i - 1) - 1
			},
			opacity = {
				min = 0,
				max = 1,
				factor = 0.1,
			}
		}

		if colorMap[overlay] then
			settings.color = {
				items = colorMap[overlay]
			}
		end

		headOverlays[overlay] = settings
	end

	local hair = {
		style = {
			min = 0,
			max = GetNumberOfPedDrawableVariations(playerPed, 2) - 1
		},
		color = {
			items = colors.hair,
		},
		highlight = {
			items = colors.hair
		},
		texture = {
			min = 0,
			max = GetNumberOfPedTextureVariations(playerPed, 2, GetPedDrawableVariation(playerPed, 2)) - 1
		}
	}

	local eyeColor = {
		min = 0,
		max = 30
	}

	return {
		ped = ped,
		components = components,
		props = props,
		headBlend = headBlend,
		faceFeatures = faceFeatures,
		headOverlays = headOverlays,
		hair = hair,
		eyeColor = eyeColor,
		tattoos = tattoos
	}
end
client.getAppearanceSettings = getAppearanceSettings

local config
function client.getConfig() return config end

local isCameraInterpolating
local currentCamera
local cameraHandle
local function setCamera(key)
	if not isCameraInterpolating then
		if key ~= 'current' then
			currentCamera = key
		end

		local coords, point = table.unpack(constants.CAMERAS[currentCamera])
		local reverseFactor = reverseCamera and -1 or 1
		local playerPed = PlayerPedId()

		if cameraHandle then
			local camCoords = GetOffsetFromEntityInWorldCoords(playerPed, coords.x * reverseFactor, coords.y * reverseFactor, coords.z * reverseFactor)
			local camPoint = GetOffsetFromEntityInWorldCoords(playerPed, point.x, point.y, point.z)
			local tmpCamera = CreateCameraWithParams('DEFAULT_SCRIPTED_CAMERA', camCoords.x, camCoords.y, camCoords.z, 0.0, 0.0, 0.0, 49.0, false, 0)

			PointCamAtCoord(tmpCamera, camPoint.x, camPoint.y, camPoint.z)
			SetCamActiveWithInterp(tmpCamera, cameraHandle, 1000, 1, 1)

			isCameraInterpolating = true

			CreateThread(function()
				repeat Wait(500)
				until not IsCamInterpolating(cameraHandle) and IsCamActive(tmpCamera)
				DestroyCam(cameraHandle, false)
				cameraHandle = tmpCamera
				isCameraInterpolating = false
			end)
		else
			local camCoords = GetOffsetFromEntityInWorldCoords(playerPed, coords.x, coords.y, coords.z)
			local camPoint = GetOffsetFromEntityInWorldCoords(playerPed, point.x, point.y, point.z)
			cameraHandle = CreateCameraWithParams('DEFAULT_SCRIPTED_CAMERA', camCoords.x, camCoords.y, camCoords.z, 0.0, 0.0, 0.0, 49.0, false, 0)

			PointCamAtCoord(cameraHandle, camPoint.x, camPoint.y, camPoint.z)
			SetCamActive(cameraHandle, true)
		end
	end
end
client.setCamera = setCamera

local reverseCamera
function client.rotateCamera(direction)
	if not isCameraInterpolating then
		local coords, point = table.unpack(constants.CAMERAS[currentCamera])
		local offset = constants.OFFSETS[currentCamera]
		local sideFactor = direction == 'left' and 1 or -1
		local reverseFactor = reverseCamera and -1 or 1
		local playerPed = PlayerPedId()

		local camCoords = GetOffsetFromEntityInWorldCoords(
			playerPed,
			(coords.x + offset.x) * sideFactor * reverseFactor,
			(coords.y + offset.y) * reverseFactor,
			coords.z
		)

		local camPoint = GetOffsetFromEntityInWorldCoords(playerPed, point.x, point.y, point.z)
		local tmpCamera = CreateCameraWithParams('DEFAULT_SCRIPTED_CAMERA', camCoords.x, camCoords.y, camCoords.z, 0.0, 0.0, 0.0, 49.0, false, 0)

		PointCamAtCoord(tmpCamera, camPoint.x, camPoint.y, camPoint.z)
		SetCamActiveWithInterp(tmpCamera, cameraHandle, 1000, 1, 1)

		isCameraInterpolating = true

		CreateThread(function()
			repeat Wait(500)
			until not IsCamInterpolating(cameraHandle) and IsCamActive(tmpCamera)
			DestroyCam(cameraHandle, false)
			cameraHandle = tmpCamera
			isCameraInterpolating = false
		end)
	end
end

local playerCoords
local function pedTurn(ped, angle)
	reverseCamera = not reverseCamera
	local sequenceTaskId = OpenSequenceTask()
	if sequenceTaskId then
		TaskGoStraightToCoord(0, playerCoords.x, playerCoords.y, playerCoords.z, 8.0, -1, GetEntityHeading(ped) - angle, 0.1)
		TaskStandStill(0, -1)
		CloseSequenceTask(sequenceTaskId)
		ClearPedTasks(ped)
		TaskPerformSequence(ped, sequenceTaskId)
		ClearSequenceTask(sequenceTaskId)
	end
end
client.pedTurn = pedTurn

local function wearClothes(data, typeClothes)
	local dataClothes = constants.DATA_CLOTHES[typeClothes]
	local playerPed = PlayerPedId()
	local animationsOn = dataClothes.animations.on
	local components = dataClothes.components[client.getPedDecorationType(playerPed)]
	local appliedComponents = data.components

	RequestAnimDict(animationsOn.dict)
	while not HasAnimDictLoaded(animationsOn.dict) do
		Wait(0)
	end

	for i = 1, #components do
		local componentId = components[i][1]
		for j = 1, #appliedComponents do
			local applied = appliedComponents[j]
			if applied.component_id == componentId then
				SetPedComponentVariation(playerPed, componentId, applied.drawable, applied.texture, 2)
			end
		end
	end

	TaskPlayAnim(playerPed, animationsOn.dict, animationsOn.anim, 3.0, 3.0, animationsOn.duration, animationsOn.move, 0, false, false, false)
end
client.wearClothes = wearClothes

local function removeClothes(typeClothes)
	local dataClothes = constants.DATA_CLOTHES[typeClothes]
	local playerPed = PlayerPedId()
	local animationsOff = dataClothes.animations.off
	local components = dataClothes.components[client.getPedDecorationType(playerPed)]
	
	RequestAnimDict(animationsOff.dict)
	while not HasAnimDictLoaded(animationsOff.dict) do
		Wait(0)
	end

	for i = 1, #components do
		local component = components[i]
		SetPedComponentVariation(playerPed, component[1], component[2], 0, 2)
	end

	TaskPlayAnim(playerPed, animationsOff.dict, animationsOff.anim, 3.0, 3.0, animationsOff.duration, animationsOff.move, 0, false, false, false)
end
client.removeClothes = removeClothes

local playerHeading
function client.getHeading() return playerHeading end



local toggleRadar = GetConvarInt('fivem-appearance:radar', 1) == 1
local callback
function client.startPlayerCustomization(cb, _config)
	local playerPed = PlayerPedId()
	playerAppearance = client.getPedAppearance(playerPed)
	playerCoords = GetEntityCoords(playerPed, true)
	playerHeading = GetEntityHeading(playerPed)

	callback = cb
	config = _config
	reverseCamera = false
	isCameraInterpolating = false

	setCamera('default')
	SetNuiFocus(true, true)
	SetNuiFocusKeepInput(false)
	RenderScriptCams(true, false, 0, true, true)
	SetEntityInvincible(playerPed, true)
	TaskStandStill(playerPed, -1)

	if toggleRadar then DisplayRadar(false) end

	SendNuiMessage(json.encode({
		type = 'appearance_display',
		payload = {}
	}))
end

function client.exitPlayerCustomization(appearance)
	RenderScriptCams(false, false, 0, true, true)
	DestroyCam(cameraHandle, false)
	SetNuiFocus(false, false)

	if toggleRadar then DisplayRadar(true) end

	local playerPed = PlayerPedId()

	ClearPedTasksImmediately(playerPed)
	SetEntityInvincible(playerPed, false)

	SendNuiMessage(json.encode({
		type = 'appearance_hide',
		payload = {}
	}))

	if not appearance then
		client.setPlayerAppearance(getAppearance())
	else
		client.setPedTattoos(playerPed, appearance.tattoos)
	end

	if callback then
		callback(appearance)
	end

	callback = nil
	config = nil
	playerAppearance = nil
	playerCoords = nil
	cameraHandle = nil
	currentCamera = nil
	reverseCamera = nil
	isCameraInterpolating = nil

end

AddEventHandler('onResourceStop', function(resource)
	if resource == GetCurrentResourceName() then
		SetNuiFocus(false, false)
		SetNuiFocusKeepInput(false)
	end
end)

exports('startPlayerCustomization', client.startPlayerCustomization)
