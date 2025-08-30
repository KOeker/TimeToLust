local CreateFrame, Settings, C_Timer = CreateFrame, Settings, C_Timer

local timeToLustDefaultConfig = {
	disableTankBLRequire = false,
	isBloodlustSoundMuted = false,
	soundChannel = 1,
	selectedBloodlustDetectionSound = nil,
	selectedTankCommandSound = "timeToLustMale.mp3",
	customSounds = {},
	debugMode = false,
	textSettings = {
		text = "TIME TO LUST!",
		font = "Fonts\\FRIZQT__.TTF",
		fontSize = 64,
		fontFlags = "OUTLINE",
		color = {r = 1, g = 0.8, b = 0, a = 1},
		shadowColor = {r = 0, g = 0, b = 0, a = 1},
		shadowOffset = {x = 4, y = -4},
		position = {x = 0, y = 150},
		scale = 1.0,
		duration = 6.0,
	}
}

local SettingsPanel = {}
SettingsPanel.__index = SettingsPanel

function SettingsPanel:new(parent, name)
	local obj = {}
	obj.parent = parent
	obj.name = name or "TimeToLust"
	obj.rows = {}
	obj.currentY = -10
	obj.rowHeight = 30
	obj.scrollChild = parent

	setmetatable(obj, self)
	return obj
end

function SettingsPanel:createOptionRowWithLabel(labelText)
	local row = CreateFrame("Frame", nil, self.scrollChild or self)
	row:SetSize(600, self.rowHeight)
	row:SetPoint("TOPLEFT", self.scrollChild or self, "TOPLEFT", 10, self.currentY)

	local label = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	label:SetPoint("LEFT", row, "LEFT", 0, 0)
	label:SetText(labelText)
	label:SetWidth(300)
	label:SetJustifyH("LEFT")

	row:Show()
	table.insert(self.rows, row)
	self.currentY = self.currentY - (self.rowHeight + 5)

	return row
end

function SettingsPanel:addButtonToLastRow(position, text, onClick)
	local row = self.rows[#self.rows]
	if not row then return end

	local button = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
	button:SetText(text)
	button:SetWidth(120)
	button:SetHeight(25)
	button:SetScript("OnClick", onClick)

	if position == 1 then
		button:SetPoint("LEFT", row, "LEFT", 310, 0)
	else
		button:SetPoint("LEFT", row, "LEFT", 440, 0)
	end

	return button
end

function SettingsPanel:addCheckboxToLastRow(position, onClick, checked)
	local row = self.rows[#self.rows]
	if not row then return end

	local checkbox = CreateFrame("CheckButton", nil, row, "InterfaceOptionsCheckButtonTemplate")
	checkbox:SetChecked(checked)
	checkbox:SetScript("OnClick", onClick)

	if position == 1 then
		checkbox:SetPoint("RIGHT", row, "CENTER", -10, 0)
	else
		checkbox:SetPoint("RIGHT", row, "RIGHT", -10, 0)
	end

	return checkbox
end

function SettingsPanel:addSliderToLastRow(position, minVal, maxVal, step, currentVal, onValueChanged)
	local row = self.rows[#self.rows]
	if not row then return end

	local slider = CreateFrame("Slider", nil, row, "OptionsSliderTemplate")
	slider:SetWidth(150)
	slider:SetHeight(20)
	slider:SetMinMaxValues(minVal, maxVal)
	slider:SetValueStep(step)
	slider:SetValue(currentVal)

	if position == 1 then
		slider:SetPoint("RIGHT", row, "CENTER", -10, 0)
	else
		slider:SetPoint("RIGHT", row, "RIGHT", -10, 0)
	end

	local text = slider:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	text:SetPoint("TOP", slider, "BOTTOM", 0, 2)
	text:SetText(currentVal)

	slider:SetScript("OnValueChanged", function(self, value)
		value = math.floor(value * 10 + 0.5) / 10
		text:SetText(value)
		onValueChanged(value)
	end)

	return slider
end

function SettingsPanel:addDropdownToLastRow(position, isSelectedFunc, setSelectedFunc, options)
	local row = self.rows[#self.rows]
	if not row then return end

	local dropdown = CreateFrame("DropdownButton", nil, row, "WowStyle1DropdownTemplate")
	dropdown:SetWidth(180)
	dropdown:SetHeight(25)

	dropdown:SetPoint("RIGHT", row, "RIGHT", -10, 0)

	local function setupMenu(dropdown, rootDescription)
		for i, option in ipairs(options) do
			local radio = rootDescription:CreateRadio(option.name, isSelectedFunc, setSelectedFunc, i)
		end
	end

	dropdown:SetupMenu(setupMenu)
	
	for i, option in ipairs(options) do
		if isSelectedFunc(i) then
			dropdown:SetText(option.name)
			break
		end
	end

	return dropdown
end

function SettingsPanel:addSoundDropdownToLastRow(position, configKey, onSoundSelected)
	local row = self.rows[#self.rows]
	if not row then return end

	local dropdown = CreateFrame("DropdownButton", nil, row, "WowStyle1DropdownTemplate")
	dropdown:SetWidth(180)
	dropdown:SetHeight(25)

	dropdown:SetPoint("RIGHT", row, "RIGHT", -10, 0)

	local function refreshSounds()
		local availableSounds = ScanSoundFiles()
		local currentSelection = TimeToLustConfig[configKey]

		local function setupMenu(dropdown, rootDescription)
			-- Stop all sounds when dropdown is opened to prevent conflicts
			StopTestSound()
			StopBloodlustSound()
			DebugPrint("Auto-stopped all sounds when sound dropdown opened")
			
			local soundCount = 0
			for filename, displayName in pairs(availableSounds) do
				soundCount = soundCount + 1
				local isSelected = (currentSelection == filename)
				rootDescription:CreateRadio(displayName, function() return TimeToLustConfig[configKey] == filename end, function()
					TimeToLustConfig[configKey] = filename
					dropdown:SetText(displayName)
					if onSoundSelected then
						onSoundSelected(filename)
					end
				end)
			end

			if soundCount == 0 then
				rootDescription:CreateTitle("No Sound Found")
			end
		end

		dropdown:SetupMenu(setupMenu)

		if currentSelection and availableSounds[currentSelection] then
			dropdown:SetText(availableSounds[currentSelection])
		else
			dropdown:SetText("Select Sound...")
		end
	end

	row.refreshSounds = refreshSounds
	refreshSounds()

	return dropdown
end

function SettingsPanel:addInputBoxToLastRow(placeholderText, onEnterPressed)
	local row = self.rows[#self.rows]
	if not row then return end

	local inputBox = CreateFrame("EditBox", nil, row, "InputBoxTemplate")
	inputBox:SetSize(150, 25)
	inputBox:SetPoint("RIGHT", row, "RIGHT", -10, 0)
	inputBox:SetAutoFocus(false)
	inputBox:SetText("")

	local placeholder = inputBox:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	placeholder:SetPoint("LEFT", inputBox, "LEFT", 5, 0)
	placeholder:SetText(placeholderText)

	inputBox:SetScript("OnEditFocusGained", function()
		placeholder:Hide()
	end)

	inputBox:SetScript("OnEditFocusLost", function()
		if inputBox:GetText() == "" then
			placeholder:Show()
		end
	end)

	inputBox:SetScript("OnEnterPressed", function()
		local text = inputBox:GetText()
		inputBox:SetText("")
		placeholder:Show()
		inputBox:ClearFocus()
		if onEnterPressed then
			onEnterPressed(text)
		end
	end)

	return inputBox
end

local TimeToLustPanelMixin = {}

function TimeToLustPanelMixin:SetupPanel()
	self.cancel = function() self:Cancel() end
	self.okay = function() if self.shownSettings then self:Save() end end
	self.shownSettings = false
	self.OnCommit = self.okay
	self.OnDefault = function() end
	self.OnRefresh = function() end

	if Settings and Settings.RegisterCanvasLayoutCategory then
		if self.parent == nil then
			local category = Settings.RegisterCanvasLayoutCategory(self, self.name)
			category.ID = self.name
			Settings.RegisterAddOnCategory(category)
		else
			local parentCategory = Settings.GetCategory(self.parent)
			local subcategory = Settings.RegisterCanvasLayoutSubcategory(parentCategory, self, self.name)
			Settings.RegisterAddOnCategory(subcategory)
		end
	else
		InterfaceOptions_AddCategory(self, self.parent or self.name)
	end
end

function TimeToLustPanelMixin:OnShow()
	self:ShowSettings()
	self.shownSettings = true
end

function TimeToLustPanelMixin:Cancel()
	-- Cancel
end

function TimeToLustPanelMixin:Save()
	-- Save
end

function TimeToLustPanelMixin:ShowSettings()
	-- Subclass
end

local function createMainPanel()
	local mainPanel = CreateFrame("Frame", "TimeToLustConfigFrame")
	mainPanel:SetSize(650, 500)
	Mixin(mainPanel, TimeToLustPanelMixin)
	mainPanel.name = "TimeToLust"
	mainPanel.parent = nil
	mainPanel:SetupPanel()

	function mainPanel:ShowSettings()
		-- Mainsettings
	end

	local settingsPanel = SettingsPanel:new(mainPanel, "TimeToLust")

	settingsPanel:createOptionRowWithLabel("Soundchannel")
	local soundChannelOptions = {
		{name = "Master"},
		{name = "Music"}
	}
	settingsPanel:addDropdownToLastRow(1, function(index)
		return TimeToLustConfig.soundChannel == index
	end, function(index)
		TimeToLustConfig.soundChannel = index
		print("TimeToLust: Sound channel changed to: " .. soundChannelOptions[index].name)
	end, soundChannelOptions)

	settingsPanel:createOptionRowWithLabel("Disable Tank BL Require")
	settingsPanel:addCheckboxToLastRow(1, function(self, _, _)
		TimeToLustConfig.disableTankBLRequire = self:GetChecked()
		if TimeToLustConfig.disableTankBLRequire then
			print("TimeToLust: Tank BL Require System deactivated")
		else
			print("TimeToLust: Tank BL Require System activated")
		end
	end, TimeToLustConfig.disableTankBLRequire)

	settingsPanel:createOptionRowWithLabel("Mute Bloodlust Sound")
	settingsPanel:addCheckboxToLastRow(1, function(self, _, _)
		TimeToLustConfig.isBloodlustSoundMuted = self:GetChecked()
		if TimeToLustConfig.isBloodlustSoundMuted then
			StopBloodlustSound()
			print("TimeToLust: Bloodlust Sound deactivated")
		else
			print("TimeToLust: Bloodlust Sound activated")
		end
	end, TimeToLustConfig.isBloodlustSoundMuted)

	return mainPanel
end

local function createSoundPanel()
	local soundPanel = CreateFrame("Frame", "TimeToLustConfigSoundsFrame")
	soundPanel:SetSize(650, 500)
	Mixin(soundPanel, TimeToLustPanelMixin)
	soundPanel.name = "Sounds"
	soundPanel.parent = "TimeToLust"
	soundPanel:SetupPanel()

	function soundPanel:ShowSettings()
		-- Soundsettings
	end

	local settingsPanel = SettingsPanel:new(soundPanel, "TimeToLustSounds")

	settingsPanel:createOptionRowWithLabel("Select Tank BL Require Sound")
	settingsPanel:addSoundDropdownToLastRow(1, "selectedTankCommandSound", function(filename)
		print("TimeToLust: Tank BL Require Sound changed to: " .. filename)
	end)

	settingsPanel:createOptionRowWithLabel("Test Tank BL Require Sound")
	settingsPanel:addButtonToLastRow(1, "Start", function()
		PlayTestSound()
	end)
	settingsPanel:addButtonToLastRow(2, "Stop", StopTestSound)

	settingsPanel:createOptionRowWithLabel("Select Bloodlust Sound")
	settingsPanel:addSoundDropdownToLastRow(1, "selectedBloodlustDetectionSound", function(filename)
		print("TimeToLust: Bloodlust Sound changed to: " .. filename)
	end)

	settingsPanel:createOptionRowWithLabel("Add Custom Sound")
	settingsPanel:addInputBoxToLastRow("Add Sound", function(text)
		if not text or text == "" then
			print("TimeToLust: Enter a file name!")
			return
		end
		
		local basePath = "Interface\\AddOns\\TimeToLust\\sound\\"
		local filename = text:lower()
		local fullPath = nil
		
		if SoundFileExists(basePath .. filename .. ".ogg", "Master") then
			fullPath = basePath .. filename .. ".ogg"
			filename = filename .. ".ogg"
		elseif SoundFileExists(basePath .. filename .. ".mp3", "Master") then
			fullPath = basePath .. filename .. ".mp3"
			filename = filename .. ".mp3"
		elseif SoundFileExists(basePath .. filename, "Master") then
			fullPath = basePath .. filename
		else
			print("TimeToLust Error: Sound '" .. text .. "' not found!")
			return
		end
		
		local displayName = text:gsub("^%l", string.upper)
		TimeToLustConfig.customSounds[fullPath] = displayName
		print("TimeToLust: Sound '" .. filename .. "' added!")
	end)

	settingsPanel:createOptionRowWithLabel("Test Bloodlust Sound")
	settingsPanel:addButtonToLastRow(1, "Start", function()
		PlayBloodlustSound()
	end)
	settingsPanel:addButtonToLastRow(2, "Stop", StopBloodlustSound)

	settingsPanel:createOptionRowWithLabel("Reset Sound Settings")
	settingsPanel:addButtonToLastRow(1, "Reset to Default", function()
		TimeToLustConfig.selectedTankCommandSound = timeToLustDefaultConfig.selectedTankCommandSound
		TimeToLustConfig.selectedBloodlustDetectionSound = timeToLustDefaultConfig.selectedBloodlustDetectionSound
		print("TimeToLust: Reset to Default Sound settings!")
	end)
	settingsPanel:addButtonToLastRow(2, "Clear Custom Sound", function()
		local customCount = 0
		for _ in pairs(TimeToLustConfig.customSounds) do
			customCount = customCount + 1
		end
		TimeToLustConfig.customSounds = {}
		print("TimeToLust: " .. customCount .. " Custom Sounds removed!")
	end)

	return soundPanel
end

local function createTextPanel()
	local textPanel = CreateFrame("Frame", "TimeToLustConfigTextFrame")
	textPanel:SetSize(650, 500)
	Mixin(textPanel, TimeToLustPanelMixin)
	textPanel.name = "Text"
	textPanel.parent = "TimeToLust"
	textPanel:SetupPanel()

	function textPanel:ShowSettings()
		-- Text
	end

	local settingsPanel = SettingsPanel:new(textPanel, "TimeToLustText")

	settingsPanel:createOptionRowWithLabel("Position X")
	settingsPanel:addSliderToLastRow(1, -2000, 2000, 10, TimeToLustConfig.textSettings.position.x, function(value)
		TimeToLustConfig.textSettings.position.x = value
		print("TimeToLust: Position X changed to: " .. value)
	end)
	
	settingsPanel:createOptionRowWithLabel("Position Y")
	settingsPanel:addSliderToLastRow(1, -1500, 1500, 10, TimeToLustConfig.textSettings.position.y, function(value)
		TimeToLustConfig.textSettings.position.y = value
		print("TimeToLust: Position Y changed to: " .. value)
	end)
	
	settingsPanel:createOptionRowWithLabel("Text Scale")
	settingsPanel:addSliderToLastRow(1, 0.5, 3.0, 0.1, TimeToLustConfig.textSettings.scale, function(value)
		TimeToLustConfig.textSettings.scale = value
		print("TimeToLust: Scaling changed to: " .. value)
	end)
	
	settingsPanel:createOptionRowWithLabel("Test Text Display")
	settingsPanel:addButtonToLastRow(1, "Show Test Text", function()
		ShowScreenText()
		print("TimeToLust: Test text shown")
	end)
	
	settingsPanel:createOptionRowWithLabel("Reset Text Settings")
	settingsPanel:addButtonToLastRow(1, "Reset to Default", function()
		TimeToLustConfig.textSettings = Deepcopy(timeToLustDefaultConfig.textSettings)
		print("TimeToLust: Text settings reset to default!")
		print("Please do: /reload ui")
	end)

	return textPanel
end

local function loadConfig(_, _, addonName)
	if addonName ~= "TimeToLust" then
		return
	end

	if type(TimeToLustConfig) == "table" then
		for defaultKey, defaultValue in pairs(timeToLustDefaultConfig) do
			if TimeToLustConfig[defaultKey] == nil then
				TimeToLustConfig[defaultKey] = defaultValue
			end
		end
		TimeToLustConfig.debugMode = timeToLustDefaultConfig.debugMode
		DebugPrint("Config after Merge - selectedBloodlustDetectionSound: " .. tostring(TimeToLustConfig.selectedBloodlustDetectionSound))
	else
		TimeToLustConfig = Deepcopy(timeToLustDefaultConfig)
		DebugPrint("New Config generated")
	end

	DebugPrint("Config loaded - selectedBloodlustDetectionSound: " .. tostring(TimeToLustConfig.selectedBloodlustDetectionSound))

	createMainPanel()
	createSoundPanel()
	createTextPanel()

	print("TimeToLust: Addon Loaded")
end

local loadFrame = CreateFrame("Frame")
loadFrame:RegisterEvent("ADDON_LOADED")
loadFrame:SetScript("OnEvent", loadConfig)
