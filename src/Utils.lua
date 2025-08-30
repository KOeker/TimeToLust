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
