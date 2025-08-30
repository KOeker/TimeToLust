local StopSound, C_Sound, PlaySoundFile, CreateFrame = StopSound, C_Sound, PlaySoundFile, CreateFrame

-- Global sound management state
local soundState = {
	isBloodlustSoundActive = false,
	isTankCommandSoundActive = false,
	lastInstanceCheck = 0,
	isInValidInstance = false
}

-- Check if player is in a valid instance for sound playing
local function IsInValidInstance()
	local currentTime = GetTime()
	-- Cache the result for 5 seconds to avoid excessive API calls
	if currentTime - soundState.lastInstanceCheck < 5 then
		return soundState.isInValidInstance
	end
	
	soundState.lastInstanceCheck = currentTime
	local inInstance, instanceType = IsInInstance()
	soundState.isInValidInstance = inInstance and (instanceType == "party" or instanceType == "raid" or instanceType == "scenario")
	return soundState.isInValidInstance
end

-- Enhanced cleanup function for all sound resources
local function CleanupAllSounds()
	DebugPrint("Performing complete sound cleanup")
	
	-- Stop tank command sound
	if TimeToLust.soundHandle then
		StopSound(TimeToLust.soundHandle)
		TimeToLust.soundHandle = nil
	end
	
	-- Stop bloodlust sound
	if TimeToLust.bloodlustSoundHandle then
		StopSound(TimeToLust.bloodlustSoundHandle)
		TimeToLust.bloodlustSoundHandle = nil
	end
	
	-- Cancel all timers
	if TimeToLust.soundCheckTimer then
		TimeToLust.soundCheckTimer:Cancel()
		TimeToLust.soundCheckTimer = nil
	end
	
	if TimeToLust.bloodlustSoundCheckTimer then
		TimeToLust.bloodlustSoundCheckTimer:Cancel()
		TimeToLust.bloodlustSoundCheckTimer = nil
	end
	
	if TimeToLust.soundStopTimer then
		TimeToLust.soundStopTimer:Cancel()
		TimeToLust.soundStopTimer = nil
	end
	
	if TimeToLust.bloodlustSoundStopTimer then
		TimeToLust.bloodlustSoundStopTimer:Cancel()
		TimeToLust.bloodlustSoundStopTimer = nil
	end
	
	-- Reset state
	soundState.isBloodlustSoundActive = false
	soundState.isTankCommandSoundActive = false
	TimeToLust.isRequireActive = false
	TimeToLust.currentBloodlustSpellId = nil
	
	-- Clear all sound tracking variables
	TimeToLust.soundStartTime = nil
	TimeToLust.soundPath = nil
	TimeToLust.soundChannel = nil
	TimeToLust.bloodlustSoundStartTime = nil
	TimeToLust.bloodlustSoundPath = nil
	TimeToLust.bloodlustSoundChannel = nil
end

local function StartSoundMonitoring(soundPath, channelIdentifier, duration)
	if not soundPath then return end
	
	-- Check if we're in a valid instance
	if not IsInValidInstance() then
		DebugPrint("Not in valid instance - skipping sound monitoring")
		return
	end
	
	soundState.isTankCommandSoundActive = true
	TimeToLust.soundStartTime = GetTime()
	TimeToLust.soundPath = soundPath
	TimeToLust.soundChannel = channelIdentifier
	
	if TimeToLust.soundCheckTimer then
		TimeToLust.soundCheckTimer:Cancel()
	end
	
	-- Add hard stop timer to prevent infinite sounds
	if TimeToLust.soundStopTimer then
		TimeToLust.soundStopTimer:Cancel()
	end
	TimeToLust.soundStopTimer = C_Timer.After(duration + 2, function()
		DebugPrint("Hard stop timer triggered for tank command sound")
		StopTestSound()
	end)
	
	TimeToLust.soundCheckTimer = C_Timer.NewTicker(0.5, function()
		-- Check if we're still in a valid instance
		if not IsInValidInstance() then
			DebugPrint("Left instance - stopping tank command sound")
			StopTestSound()
			return
		end
		
		-- Check if bloodlust sound is active - if so, mute tank command
		if soundState.isBloodlustSoundActive then
			DebugPrint("Bloodlust sound active - muting tank command sound")
			if TimeToLust.soundHandle then
				StopSound(TimeToLust.soundHandle)
				TimeToLust.soundHandle = nil
			end
			return
		end
		
		if TimeToLust.soundHandle then
			if not C_Sound.IsPlaying(TimeToLust.soundHandle) then
				local elapsed = GetTime() - TimeToLust.soundStartTime
				local remainingTime = duration - elapsed
				
				if remainingTime > 0.5 and not soundState.isBloodlustSoundActive then
					DebugPrint("Tank sound stopped at " .. string.format("%.1f", elapsed) .. "s - Restarting for remaining " .. string.format("%.1f", remainingTime) .. "s")
					
					local restartSuccess, newHandle = PlaySoundFile(TimeToLust.soundPath, TimeToLust.soundChannel)
					if restartSuccess then
						TimeToLust.soundHandle = newHandle
						DebugPrint("Tank sound restarted successfully")
						
						C_Timer.After(remainingTime, function()
							if TimeToLust.soundHandle == newHandle then
								StopSound(newHandle)
								DebugPrint("Tank sound stopped after remaining time")
							end
						end)
					else
						DebugPrint("Failed to restart tank sound")
					end
				else
					DebugPrint("Tank sound finished or bloodlust active - stopping monitoring")
					StopTestSound()
				end
			end
		end
	end)
end

local function StartBloodlustSoundMonitoring(soundPath, channelIdentifier, duration)
	if not soundPath then return end
	
	-- Check if we're in a valid instance
	if not IsInValidInstance() then
		DebugPrint("Not in valid instance - skipping bloodlust sound monitoring")
		return
	end
	
	soundState.isBloodlustSoundActive = true
	TimeToLust.bloodlustSoundStartTime = GetTime()
	TimeToLust.bloodlustSoundPath = soundPath
	TimeToLust.bloodlustSoundChannel = channelIdentifier
	
	if TimeToLust.bloodlustSoundCheckTimer then
		TimeToLust.bloodlustSoundCheckTimer:Cancel()
	end
	
	-- Add hard stop timer for bloodlust sound
	if TimeToLust.bloodlustSoundStopTimer then
		TimeToLust.bloodlustSoundStopTimer:Cancel()
	end
	TimeToLust.bloodlustSoundStopTimer = C_Timer.After(duration + 2, function()
		DebugPrint("Hard stop timer triggered for bloodlust sound")
		StopBloodlustSound()
	end)
	
	TimeToLust.bloodlustSoundCheckTimer = C_Timer.NewTicker(0.5, function()
		-- Check if we're still in a valid instance
		if not IsInValidInstance() then
			DebugPrint("Left instance - stopping bloodlust sound")
			StopBloodlustSound()
			return
		end
		
		if TimeToLust.bloodlustSoundHandle then
			if not C_Sound.IsPlaying(TimeToLust.bloodlustSoundHandle) then
				local elapsed = GetTime() - TimeToLust.bloodlustSoundStartTime
				local remainingTime = duration - elapsed
				
				if remainingTime > 0.5 then
					DebugPrint("Bloodlust sound stopped at " .. string.format("%.1f", elapsed) .. "s - Restarting for remaining " .. string.format("%.1f", remainingTime) .. "s")
					
					local restartSuccess, newHandle = PlaySoundFile(TimeToLust.bloodlustSoundPath, TimeToLust.bloodlustSoundChannel)
					if restartSuccess then
						TimeToLust.bloodlustSoundHandle = newHandle
						DebugPrint("Bloodlust sound restarted successfully")
						
						C_Timer.After(remainingTime, function()
							if TimeToLust.bloodlustSoundHandle == newHandle then
								StopSound(newHandle)
								DebugPrint("Bloodlust sound stopped after remaining time")
							end
						end)
					else
						DebugPrint("Failed to restart bloodlust sound")
					end
				else
					DebugPrint("Bloodlust sound finished - stopping monitoring")
					StopBloodlustSound()
				end
			end
		end
	end)
end

function StopTestSound()
	DebugPrint("Stopping tank command sound")
	
	if TimeToLust.soundHandle then
		StopSound(TimeToLust.soundHandle)
		TimeToLust.soundHandle = nil
	end
	
	if TimeToLust.soundCheckTimer then
		TimeToLust.soundCheckTimer:Cancel()
		TimeToLust.soundCheckTimer = nil
	end
	
	if TimeToLust.soundStopTimer then
		TimeToLust.soundStopTimer:Cancel()
		TimeToLust.soundStopTimer = nil
	end
	
	soundState.isTankCommandSoundActive = false
	TimeToLust.soundStartTime = nil
	TimeToLust.soundPath = nil
	TimeToLust.soundChannel = nil
end

function StopBloodlustSound()
	DebugPrint("Stopping bloodlust sound")
	
	if TimeToLust.bloodlustSoundHandle then
		StopSound(TimeToLust.bloodlustSoundHandle)
		TimeToLust.bloodlustSoundHandle = nil
	end
	
	TimeToLust.currentBloodlustSpellId = nil
	
	if TimeToLust.bloodlustSoundCheckTimer then
		TimeToLust.bloodlustSoundCheckTimer:Cancel()
		TimeToLust.bloodlustSoundCheckTimer = nil
	end
	
	if TimeToLust.bloodlustSoundStopTimer then
		TimeToLust.bloodlustSoundStopTimer:Cancel()
		TimeToLust.bloodlustSoundStopTimer = nil
	end
	
	soundState.isBloodlustSoundActive = false
	TimeToLust.bloodlustSoundStartTime = nil
	TimeToLust.bloodlustSoundPath = nil
	TimeToLust.bloodlustSoundChannel = nil
end

function PlayBloodlustSound()
	if TimeToLustConfig.isBloodlustSoundMuted then
		return
	end
	
	-- Check if we're in a valid instance
	if not IsInValidInstance() then
		DebugPrint("Not in valid instance - skipping bloodlust sound")
		return
	end
	
	-- Stop any currently playing tank command sound to avoid conflicts
	if soundState.isTankCommandSoundActive then
		DebugPrint("Stopping tank command sound to play bloodlust sound")
		StopTestSound()
	end

	if not TimeToLustConfig.selectedBloodlustDetectionSound then
		print("TimeToLust: No Bloodlust Sound selected")
		return
	end

	local success
	local channelIdentifier = TimeToLust.soundChannels[TimeToLustConfig.soundChannel].identifier
	local soundPath = GetSoundPath(TimeToLustConfig.selectedBloodlustDetectionSound)
	
	if soundPath then
		success, TimeToLust.bloodlustSoundHandle = PlaySoundFile(soundPath, channelIdentifier)
	end
	
	if not success then
		success, TimeToLust.bloodlustSoundHandle = PlaySoundFile(567450, channelIdentifier)
		soundPath = nil
	end
	
	if success and soundPath then
		StartBloodlustSoundMonitoring(soundPath, channelIdentifier, 300)
	end
	
	DebugPrint("Bloodlust-Sound started (" .. (TimeToLustConfig.selectedBloodlustDetectionSound or "fallback") .. ") - Handle: " .. tostring(TimeToLust.bloodlustSoundHandle))
end

function PlayTankCommandSound()
	if TimeToLustConfig.disableTankBLRequire then
		return
	end
	
	-- Check if we're in a valid instance
	if not IsInValidInstance() then
		DebugPrint("Not in valid instance - skipping tank command sound")
		return
	end
	
	-- Don't play tank command sound if bloodlust sound is active
	if soundState.isBloodlustSoundActive then
		DebugPrint("Bloodlust sound is active - muting tank command sound")
		return
	end
	
	local selectedSound = TimeToLustConfig.selectedTankCommandSound
	local soundPath = GetSoundPath(selectedSound)
	local success
	local channelIdentifier = TimeToLust.soundChannels[TimeToLustConfig.soundChannel].identifier
	
	if soundPath and SoundFileExists(soundPath) then
		success, TimeToLust.soundHandle = PlaySoundFile(soundPath, channelIdentifier)
	else
		soundPath = "Interface\\AddOns\\TimeToLust\\sound\\timeToLustMale.mp3"
		success, TimeToLust.soundHandle = PlaySoundFile(soundPath, channelIdentifier)
	end
	
	if not success then
		success, TimeToLust.soundHandle = PlaySoundFile(567451, channelIdentifier)
		soundPath = nil
	end
	
	if success and soundPath then
		StartSoundMonitoring(soundPath, channelIdentifier, 6)
	end
	
	DebugPrint("Tank Command Sound (" .. (selectedSound or "fallback") .. ") started - Handle: " .. tostring(TimeToLust.soundHandle) .. ", Success: " .. tostring(success))
end

function PlayTestSound()
	local selectedSound = TimeToLustConfig.selectedTankCommandSound
	local soundPath = GetSoundPath(selectedSound)
	local success
	local channelIdentifier = TimeToLust.soundChannels[TimeToLustConfig.soundChannel].identifier
	
	if soundPath and SoundFileExists(soundPath) then
		success, TimeToLust.soundHandle = PlaySoundFile(soundPath, channelIdentifier)
	else
		soundPath = "Interface\\AddOns\\TimeToLust\\sound\\timeToLustMale.mp3"
		success, TimeToLust.soundHandle = PlaySoundFile(soundPath, channelIdentifier)
	end
	
	if not success then
		success, TimeToLust.soundHandle = PlaySoundFile(567451, channelIdentifier)
		soundPath = nil
	end
	
	if success and soundPath then
		StartSoundMonitoring(soundPath, channelIdentifier, 30)
	end
	
	DebugPrint("Tank Command Test Sound (" .. (selectedSound or "fallback") .. ") started - Handle: " .. tostring(TimeToLust.soundHandle) .. ", Success: " .. tostring(success))
end

function ShowScreenText(customText)
	local settings = TimeToLustConfig.textSettings or {}
	local displayText = customText or settings.text or "TIME TO LUST!"
	
	local frame = CreateFrame("Frame", nil, UIParent)
	frame:SetFrameStrata("FULLSCREEN_DIALOG")
	frame:SetSize(1000, 150)
	
	local posX = settings.position and settings.position.x or 0
	local posY = settings.position and settings.position.y or 150
	frame:SetPoint("CENTER", UIParent, "CENTER", posX, posY)
	
	local fontString = frame:CreateFontString(nil, "OVERLAY")
	fontString:SetPoint("CENTER", frame, "CENTER")
	
	local fontPath = settings.font or "Fonts\\FRIZQT__.TTF"
	local fontSize = settings.fontSize or 64
	local fontFlags = settings.fontFlags or "OUTLINE"
	local success = fontString:SetFont(fontPath, fontSize, fontFlags)
	
	if not success then
		fontString:SetFontObject("GameFontHighlightHuge")
		local scale = fontSize / 64
		fontString:SetTextScale(scale)
	end
	
	fontString:SetText(displayText)
	
	local color = settings.color or {r = 1, g = 0.8, b = 0, a = 1}
	fontString:SetTextColor(color.r, color.g, color.b, color.a)
	
	local shadowColor = settings.shadowColor or {r = 0, g = 0, b = 0, a = 1}
	fontString:SetShadowColor(shadowColor.r, shadowColor.g, shadowColor.b, shadowColor.a)
	
	local shadowOffset = settings.shadowOffset or {x = 4, y = -4}
	fontString:SetShadowOffset(shadowOffset.x, shadowOffset.y)
	
	local scale = settings.scale or 1.0
	fontString:SetTextScale(scale)
	
	local glowFrames = {}
	
	C_Timer.After(0.01, function()
		if not frame then return end
		
		local textWidth = fontString:GetStringWidth()
		local textHeight = fontString:GetStringHeight()
		
		if textWidth > 0 and textHeight > 0 then
			local glowSizes = {4, 8, 12}
			local glowAlphas = {0.3, 0.2, 0.1}
			
			for i, size in ipairs(glowSizes) do
				local glowFrame = CreateFrame("Frame", nil, frame)
				glowFrame:SetPoint("CENTER", fontString, "CENTER")
				glowFrame:SetSize(textWidth + size, textHeight + size)
				
				local glowTexture = glowFrame:CreateTexture(nil, "BACKGROUND")
				glowTexture:SetAllPoints(glowFrame)
				glowTexture:SetColorTexture(1, 0.8, 0, glowAlphas[i])
				glowTexture:SetBlendMode("ADD")
				
				table.insert(glowFrames, {frame = glowFrame, texture = glowTexture})
			end
			
			if #glowFrames > 0 then
				setupGlowAnimation(frame, glowFrames, glowAlphas)
			end
		end
	end)
	
	frame:SetAlpha(1)
	frame:Show()
	
	frame.startFadeOut = function()
		local fadeOut = frame:CreateAnimationGroup()
		local fadeOutAnim = fadeOut:CreateAnimation("Alpha")
		fadeOutAnim:SetFromAlpha(1)
		fadeOutAnim:SetToAlpha(0)
		fadeOutAnim:SetDuration(1.5)
		fadeOut:SetScript("OnFinished", function()
			if frame.glowPulse then
				frame.glowPulse:Stop()
			end
			frame:Hide()
			frame = nil
		end)
		fadeOut:Play()
	end
	
	C_Timer.After(5, function()
		if frame and frame.startFadeOut then
			DebugPrint("Starting text fade-out after 5 seconds")
			frame.startFadeOut()
		end
	end)
end

function setupGlowAnimation(frame, glowFrames, glowAlphas)
	if not frame or #glowFrames == 0 then return end
	
	local glowPulse = CreateFrame("Frame"):CreateAnimationGroup()
	glowPulse:SetLooping("REPEAT")
	
	for i, glowData in ipairs(glowFrames) do
		local pulseAlpha = glowPulse:CreateAnimation("Alpha")
		pulseAlpha:SetTarget(glowData.texture)
		pulseAlpha:SetFromAlpha(glowAlphas[i])
		pulseAlpha:SetToAlpha(glowAlphas[i] * 0.5)
		pulseAlpha:SetDuration(2.0)
		pulseAlpha:SetOrder(1)
		
		local pulseAlphaBack = glowPulse:CreateAnimation("Alpha")
		pulseAlphaBack:SetTarget(glowData.texture)
		pulseAlphaBack:SetFromAlpha(glowAlphas[i] * 0.5)
		pulseAlphaBack:SetToAlpha(glowAlphas[i])
		pulseAlphaBack:SetDuration(2.0)
		pulseAlphaBack:SetOrder(2)
	end
	
	frame.glowPulse = glowPulse
	
	glowPulse:Play()
end

function OnKeybindPressed()
	DebugPrint("Keybind pressed!")
	
	if TimeToLust.isRequireActive then
		print("TimeToLust: Require is already active!")
		return
	end
	
	if not IsPlayerTank() then
		print("TimeToLust: Only Tanks can require BL!")
		return
	end
	
	if not IsInGroup() then
		print("TimeToLust: You have to be in a group!")
		return
	end

	local channel = IsInRaid() and "RAID" or "PARTY"
	DebugPrint("Send over " .. channel .. " channel")
	
	local success = C_ChatInfo.SendAddonMessage("TimeToLust", "BLOODLUST_NOW", channel)
	DebugPrint("Message send - Success: " .. tostring(success))
end

function OnAddonMessage(prefix, message, channel, sender)
	if prefix ~= "TimeToLust" then
		return
	end

	if message == "BLOODLUST_NOW" then
		DebugPrint("Message from: " .. sender)
		
		if TimeToLustConfig.disableTankBLRequire then
			print("TimeToLust: Tank BL Require System is deactivated - Message ignored")
			return
		end
		
		DebugPrint("IsDPS=" .. tostring(IsPlayerDPS()) .. ", IsHealer=" .. tostring(IsPlayerHealer()) .. ", HasBL=" .. tostring(PlayerHasBloodlust()))
		
		if TimeToLust.isRequireActive then
			if IsPlayerTank() then
				print("TimeToLust: Bloodlust already required!")
			end
			return
		end
		
		if (IsPlayerDPS() or IsPlayerHealer()) and PlayerHasBloodlust() then
			TimeToLust.isRequireActive = true
			
			PlayTankCommandSound()
			ShowScreenText()
			
			C_Timer.After(6, function()
				TimeToLust.isRequireActive = false
				if TimeToLust.soundHandle then
					StopSound(TimeToLust.soundHandle)
				end
				if TimeToLust.soundCheckTimer then
					TimeToLust.soundCheckTimer:Cancel()
					TimeToLust.soundCheckTimer = nil
				end
				TimeToLust.soundStartTime = nil
				TimeToLust.soundPath = nil
				TimeToLust.soundChannel = nil
				DebugPrint("Require finished - All timers stopped")
			end)
		end
	elseif message:match("^BLOODLUST_APPLIED:(.+)$") then
		local spellId = tonumber(message:match("^BLOODLUST_APPLIED:(.+)$"))
		PlayBloodlustSound()
		TimeToLust.currentBloodlustSpellId = spellId
	elseif message:match("^BLOODLUST_REMOVED:(.+)$") then
		local spellId = tonumber(message:match("^BLOODLUST_REMOVED:(.+)$"))
		if TimeToLust.currentBloodlustSpellId == spellId then
			StopBloodlustSound()
		end
	end
end

local function setupErrorSuppression()
	if UIErrorsFrame and UIErrorsFrame.AddMessage then
		local originalAddMessage = UIErrorsFrame.AddMessage
		
		UIErrorsFrame.AddMessage = function(self, text, r, g, b, id, ...)
			local textStr = tostring(text or "")
			
			if textStr:find("TimeToLust/Bindings%.xml") and
			   (textStr:find("Unrecognized XML") or 
			    textStr:find("Unrecognized XML attribute")) then
				DebugPrint("XML-Error unterdrückt: " .. textStr)
				return
			end
			
			return originalAddMessage(self, text, r, g, b, id, ...)
		end
		
		DebugPrint("UIErrorsFrame Error-Suppression aktiviert")
	end
	
	local originalPrint = print
	_G.print = function(...)
		local args = {...}
		local text = ""
		for i, arg in ipairs(args) do
			text = text .. tostring(arg)
			if i < #args then text = text .. " " end
		end
		
		if text:find("TimeToLust/Bindings%.xml") and
		   (text:find("Unrecognized XML") or 
		    text:find("Unrecognized XML attribute")) then
			if TimeToLustConfig and TimeToLustConfig.debugMode then
				originalPrint("TimeToLust DEBUG: Console error removed: " .. text)
			end
			return
		end
		
		return originalPrint(...)
	end
	
	DebugPrint("Console Error-Suppression active")
end

local function setupKeybinds()
	BINDING_NAME_TIMETOLUST_KEYBIND = "TimeToLust Hotkey"
	
	SLASH_TIMETOLUST1 = "/timetolust"
	SLASH_TIMETOLUST2 = "/ttl"
	SlashCmdList["TIMETOLUST"] = function(msg)
		if msg == "trigger" or msg == "" then
			OnKeybindPressed()
		elseif msg == "config" then
			Settings.OpenToCategory("TimeToLust")
		elseif msg == "stop" or msg == "stopsounds" then
			CleanupAllSounds()
			print("TimeToLust: All sounds stopped and cleaned up")
		elseif msg == "errors" then
			if TimeToLustConfig and TimeToLustConfig.suppressXMLErrors == nil then
				TimeToLustConfig.suppressXMLErrors = true
			end
			TimeToLustConfig.suppressXMLErrors = not TimeToLustConfig.suppressXMLErrors
			
			if TimeToLustConfig.suppressXMLErrors then
				setupErrorSuppression()
				print("TimeToLust: XML-Error-Suppression activated")
			else
				print("TimeToLust: XML-Error-Suppression deactivated (Needs restart)")
			end
		else
			print("TimeToLust Commands:")
			print("/timetolust trigger - Trigger Keybind-Action")
			print("/timetolust config - Open Config")
			print("/timetolust stop - Stop all sounds immediately")
			print("/timetolust errors - Toggle XML Error Suppression")
		end
	end
end

function TIMETOLUST_KEYBIND()
	OnKeybindPressed()
end

local bloodlustFrame = CreateFrame("Frame")
bloodlustFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
bloodlustFrame:SetScript("OnEvent", function(_, _)
	local _, subevent, _, _, _, _, _, destinationGUID, _, _, _, auraId = CombatLogGetCurrentEventInfo()
	
	if not IsInGroup() then
		return
	end
	
	if subevent == "SPELL_AURA_APPLIED" and TimeToLust.isBloodLustAuraId(auraId) then
		local channel = IsInRaid() and "RAID" or "PARTY"
		C_ChatInfo.SendAddonMessage("TimeToLust", "BLOODLUST_APPLIED:" .. auraId, channel)
		DebugPrint("Bloodlust used")
	end
	
	if subevent == "SPELL_AURA_REMOVED" and auraId == TimeToLust.currentBloodlustSpellId then
		local channel = IsInRaid() and "RAID" or "PARTY"
		C_ChatInfo.SendAddonMessage("TimeToLust", "BLOODLUST_REMOVED:" .. auraId, channel)
		DebugPrint("Bloodlust done")
	end
end)

-- Add cleanup event handlers
local cleanupFrame = CreateFrame("Frame")
cleanupFrame:RegisterEvent("PLAYER_LEAVING_WORLD")
cleanupFrame:RegisterEvent("PLAYER_ENTERING_WORLD") 
cleanupFrame:RegisterEvent("GROUP_LEFT")
cleanupFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
cleanupFrame:SetScript("OnEvent", function(self, event, ...)
	if event == "PLAYER_LEAVING_WORLD" then
		DebugPrint("Player leaving world - cleaning up all sounds")
		CleanupAllSounds()
	elseif event == "PLAYER_ENTERING_WORLD" then
		DebugPrint("Player entering world - resetting sound state")
		soundState.lastInstanceCheck = 0 -- Force instance check refresh
	elseif event == "GROUP_LEFT" then
		DebugPrint("Left group - cleaning up all sounds")
		CleanupAllSounds()
	elseif event == "ZONE_CHANGED_NEW_AREA" then
		-- Check if we left an instance
		C_Timer.After(1, function() -- Small delay to let the zone change complete
			if not IsInValidInstance() and (soundState.isBloodlustSoundActive or soundState.isTankCommandSoundActive) then
				DebugPrint("Left instance area - cleaning up sounds")
				CleanupAllSounds()
			end
		end)
	end
end)

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("CHAT_MSG_ADDON")
eventFrame:SetScript("OnEvent", function(self, event, ...)
	if event == "ADDON_LOADED" then
		local addonName = ...
		if addonName == "TimeToLust" then
			setupErrorSuppression()
			
			setupKeybinds()
			local success = C_ChatInfo.RegisterAddonMessagePrefix("TimeToLust")
			DebugPrint("Addon-Prefix registered - Success: " .. tostring(success))
		end
	elseif event == "CHAT_MSG_ADDON" then
		local prefix, message, channel, sender = ...
		DebugPrint("CHAT_MSG_ADDON Event: " .. tostring(prefix))
		OnAddonMessage(prefix, message, channel, sender)
	end
end)
