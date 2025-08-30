local UnitGUID = UnitGUID

TimeToLust = {
	playerGUID = UnitGUID("player"),
	soundHandle = nil,
	bloodlustSoundHandle = nil,
	currentBloodlustSpellId = nil,
	isRequireActive = false,
	soundStartTime = nil,
	soundPath = nil,
	soundChannel = nil,
	soundCheckTimer = nil,
	soundStopTimer = nil,
	bloodlustSoundStartTime = nil,
	bloodlustSoundPath = nil,
	bloodlustSoundChannel = nil,
	bloodlustSoundCheckTimer = nil,
	bloodlustSoundStopTimer = nil,
	soundChannels = {
		{
			identifier = "Master",
			name = "Master",
			volume = "Sound_MasterVolume",
			enable = "Sound_EnableAllSound",
		},
		{
			identifier = "Music",
			name = "Music",
			volume = "Sound_MusicVolume",
			enable = "Sound_EnableMusic",
		},
	},
	-- Bloodlust/Heroism
	auraIds = {
        386540, -- temporal warp
        368245, -- resonant bloodlust
        -- drums
        146555, -- drums of rage
        178207, -- drums of fury
        441076, -- timeless drums
        230935, -- drums of the mountain
        256740, -- drums of the maelstrom
        309658, -- drums of deathly ferocity
        381301, -- feral hide drums
        444257, -- thunderous drums
        -- hunter
        466904, -- harriers cry
        264667, -- primal rage
        --shaman
        32182,  -- heroism
        2825,   -- bloodlust
        -- mage
        80353,  -- time warp (mage)
        350249, -- time warp (mage)
        -- evoker
        390386, -- fury of the aspects
	},
	isBloodLustAuraId = function(auraId)
		for _, id in ipairs(TimeToLust.auraIds) do
			if id == auraId then
				return true
			end
		end
		return false
	end,
}

function DebugPrint(message)
	if TimeToLustConfig and TimeToLustConfig.debugMode then
		print("TimeToLust DEBUG: " .. message)
	end
end

local function earlyErrorSuppression()
	if UIErrorsFrame and UIErrorsFrame.AddMessage then
		local originalAddMessage = UIErrorsFrame.AddMessage
		
		UIErrorsFrame.AddMessage = function(self, text, r, g, b, id, ...)
			local textStr = tostring(text or "")
			
			if textStr:find("TimeToLust") and textStr:find("Bindings%.xml") and
			   (textStr:find("Unrecognized XML") or textStr:find("Unrecognized")) then
				if _G.TimeToLustConfig and _G.TimeToLustConfig.debugMode then
					print("TimeToLust DEBUG: Early XML-Error: " .. textStr)
				end
				return
			end
			
			return originalAddMessage(self, text, r, g, b, id, ...)
		end
	end
	
	local originalScriptErrors = GetCVar("scriptErrors")
	if originalScriptErrors == "1" then
		local frame = CreateFrame("Frame")
		frame:RegisterEvent("ADDON_LOADED")
		frame:SetScript("OnEvent", function(self, event, addonName)
			if addonName == "TimeToLust" then
				SetCVar("scriptErrors", "0")
				
				C_Timer.After(2, function()
					SetCVar("scriptErrors", originalScriptErrors)
				end)
			end
		end)
	end
end

earlyErrorSuppression()
