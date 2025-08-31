local GetCVar, SetCVar, PlaySoundFile, StopSound = GetCVar, SetCVar, PlaySoundFile, StopSound

function Deepcopy(orig, copies)
	copies = copies or {}
	local orig_type = type(orig)
	local copy
	if orig_type == "table" then
		if copies[orig] then
			copy = copies[orig]
		else
			copy = {}
			copies[orig] = copy
			for orig_key, orig_value in next, orig, nil do
				copy[Deepcopy(orig_key, copies)] = Deepcopy(orig_value, copies)
			end
			setmetatable(copy, Deepcopy(getmetatable(orig), copies))
		end
	else
		copy = orig
	end
	return copy
end

function SoundFileExists(path, soundChannel)
	local enableAllSound = GetCVar("Sound_EnableAllSound")
	local channel = soundChannel or "Master"

	SetCVar("Sound_EnableAllSound", 1)

	local willPlay, soundHandle = PlaySoundFile(path, channel)

	if willPlay then
		StopSound(soundHandle)
	end

	SetCVar("Sound_EnableAllSound", enableAllSound)

	return willPlay
end

local activeSounds = {}
local originalVolumes = {}
local volumeInitialized = {}

local activeSoundTypes = {
	tank = false,
	bloodlust = false
}

local function UpdateSliderStates()
	if _G.TimeToLustSliders then
		if _G.TimeToLustSliders.tankSlider then
			_G.TimeToLustSliders.tankSlider:SetEnabled(not activeSoundTypes.tank)
			if activeSoundTypes.tank then
				_G.TimeToLustSliders.tankSlider:SetAlpha(0.5)
			else
				_G.TimeToLustSliders.tankSlider:SetAlpha(1.0)
			end
		end
		
		if _G.TimeToLustSliders.bloodlustSlider then
			_G.TimeToLustSliders.bloodlustSlider:SetEnabled(not activeSoundTypes.bloodlust)
			if activeSoundTypes.bloodlust then
				_G.TimeToLustSliders.bloodlustSlider:SetAlpha(0.5)
			else
				_G.TimeToLustSliders.bloodlustSlider:SetAlpha(1.0)
			end
		end
	end
end

function PlaySoundFileWithVolume(soundPath, channel, volume, duration, soundType)
	if not soundPath then
		return PlaySoundFile(soundPath, channel)
	end
	
	if volume == nil then
		volume = 1.0
	end
	
	volume = math.max(0.1, volume)
	
	if not duration then
		duration = 30
	end
	
	if not soundType then
		soundType = "generic"
	end
	
	if soundType:find("tank") then
		activeSoundTypes.tank = true
		UpdateSliderStates()
	elseif soundType:find("bloodlust") then
		activeSoundTypes.bloodlust = true
		UpdateSliderStates()
	end
	
	local volumeCVar = "Sound_MasterVolume"
	if channel == "Music" then
		volumeCVar = "Sound_MusicVolume"
	elseif channel == "SFX" then
		volumeCVar = "Sound_SFXVolume"
	end
	
	if not volumeInitialized[volumeCVar] then
		originalVolumes[volumeCVar] = tonumber(GetCVar(volumeCVar)) or 1.0
		volumeInitialized[volumeCVar] = true
		DebugPrint("Original volume stored for " .. volumeCVar .. ": " .. originalVolumes[volumeCVar])
	end
	
	local adjustedVolume = math.max(0, math.min(1, originalVolumes[volumeCVar] * volume))
	
	DebugPrint("Volume Control [" .. soundType .. "]: Original=" .. originalVolumes[volumeCVar] .. ", User=" .. volume .. ", Adjusted=" .. adjustedVolume .. ", Duration=" .. duration .. "s")
	
	if activeSounds[soundType] then
		activeSounds[soundType]:Cancel()
		DebugPrint("Cancelled previous timer for sound type: " .. soundType)
	end
	
	local lowestVolume = volume
	for activeType, _ in pairs(activeSounds) do
		if activeType:find(volumeCVar) then
			local storedVolume = tonumber(activeType:match("_vol_([%d%.]+)"))
			if storedVolume and storedVolume < lowestVolume then
				lowestVolume = storedVolume
			end
		end
	end
	
	local finalAdjustedVolume = math.max(0, math.min(1, originalVolumes[volumeCVar] * lowestVolume))
	
	SetCVar(volumeCVar, finalAdjustedVolume)
	
	local success, handle = PlaySoundFile(soundPath, channel)
	
	local soundId = soundType .. "_" .. volumeCVar .. "_vol_" .. volume
	
	activeSounds[soundId] = C_Timer.After(duration + 1, function()
		activeSounds[soundId] = nil
		DebugPrint("Sound finished: " .. soundType)
		
		local hasTankSounds = false
		local hasBloodlustSounds = false
		
		for activeId, _ in pairs(activeSounds) do
			if activeId:find("tank") then
				hasTankSounds = true
			elseif activeId:find("bloodlust") then
				hasBloodlustSounds = true
			end
		end
		
		activeSoundTypes.tank = hasTankSounds
		activeSoundTypes.bloodlust = hasBloodlustSounds
		UpdateSliderStates()
		
		local hasActiveSounds = false
		local newLowestVolume = 1.0
		
		for activeId, _ in pairs(activeSounds) do
			if activeId:find(volumeCVar) then
				hasActiveSounds = true
				local storedVolume = tonumber(activeId:match("_vol_([%d%.]+)"))
				if storedVolume and storedVolume < newLowestVolume then
					newLowestVolume = storedVolume
				end
			end
		end
		
		if hasActiveSounds then
			local newAdjustedVolume = math.max(0, math.min(1, originalVolumes[volumeCVar] * newLowestVolume))
			SetCVar(volumeCVar, newAdjustedVolume)
			DebugPrint("Volume adjusted to new lowest: " .. newAdjustedVolume .. " for " .. volumeCVar)
		else
			local originalVol = originalVolumes[volumeCVar]
			if originalVol then
				SetCVar(volumeCVar, originalVol)
				DebugPrint("Volume fully restored to: " .. originalVol .. " for " .. volumeCVar)
			else
				DebugPrint("Warning: No original volume found for " .. volumeCVar .. ", setting to 1.0")
				SetCVar(volumeCVar, 1.0)
			end
		end
	end)
	
	return success, handle
end

function CleanupVolumeSystem()
	DebugPrint("Cleaning up volume system")
	
	for soundId, timer in pairs(activeSounds) do
		if timer then
			timer:Cancel()
			DebugPrint("Cancelled timer for: " .. soundId)
		end
	end
	activeSounds = {}
	
	for volumeCVar, originalVol in pairs(originalVolumes) do
		if originalVol then
			SetCVar(volumeCVar, originalVol)
			DebugPrint("Emergency restore: " .. volumeCVar .. " to " .. originalVol)
		end
	end
	
	activeSoundTypes.tank = false
	activeSoundTypes.bloodlust = false
	UpdateSliderStates()
	
	DebugPrint("Volume system cleanup complete")
end

function IsPlayerTank()
	if IsInGroup() then
		local assignedRole = UnitGroupRolesAssigned("player")
		if assignedRole == "TANK" then
			return true
		end
	end
	
	local specIndex = GetSpecialization()
	if not specIndex then
		return false
	end
	
	local _, _, _, _, role = GetSpecializationInfo(specIndex)
	return role == "TANK"
end

function IsPlayerDPS()
	if IsInGroup() then
		local assignedRole = UnitGroupRolesAssigned("player")
		if assignedRole == "DAMAGER" then
			return true
		end
	end
	
	local specIndex = GetSpecialization()
	if not specIndex then
		return false
	end
	
	local _, _, _, _, role = GetSpecializationInfo(specIndex)
	return role == "DAMAGER"
end

function IsPlayerHealer()
	if IsInGroup() then
		local assignedRole = UnitGroupRolesAssigned("player")
		if assignedRole == "HEALER" then
			return true
		end
	end
	
	local specIndex = GetSpecialization()
	if not specIndex then
		return false
	end
	
	local _, _, _, _, role = GetSpecializationInfo(specIndex)
	return role == "HEALER"
end

function PlayerHasBloodlust()
	local playerClass = select(2, UnitClass("player"))
	
	local bloodlustClasses = {
		["SHAMAN"] = true,
		["MAGE"] = true,
		["HUNTER"] = true,
		["EVOKER"] = true,
	}
	
	DebugPrint("Class=" .. playerClass .. ", HasBL=" .. tostring(bloodlustClasses[playerClass] == true))
	return bloodlustClasses[playerClass] == true
end

function ScanSoundFiles()
	local soundFiles = {}
	local basePath = "Interface\\AddOns\\TimeToLust\\sound\\"

	if TimeToLustConfig and TimeToLustConfig.customSounds then
		for fullPath, displayName in pairs(TimeToLustConfig.customSounds) do
			if SoundFileExists(fullPath, "Master") then
				local filename = fullPath:match("([^\\]+)$")
				if filename then
					soundFiles[filename] = displayName
					DebugPrint("Custom Sound loaded: " .. filename .. " -> " .. displayName)
				end
			end
		end
	end
	
	local possibleSounds = {
		"timeToLustMale.mp3",
        "timeToLustFemale.mp3",
		
	}
	
	for _, filename in ipairs(possibleSounds) do
		local fullPath = basePath .. filename
		if SoundFileExists(fullPath, "Master") then
			local displayName = filename:gsub("%.mp3$", ""):gsub("%.ogg$", "")
			displayName = displayName:gsub("^%l", string.upper)
			soundFiles[filename] = displayName
			DebugPrint("Sound found: " .. filename .. " -> " .. displayName)
		end
	end
	
	return soundFiles
end

function GetSoundPath(filename)
	if not filename then
		return nil
	end
	
	local basePath = "Interface\\AddOns\\TimeToLust\\sound\\"
	local fullPath = basePath .. filename
	
	if SoundFileExists(fullPath, "Master") then
		return fullPath
	end
	
	return nil
end
