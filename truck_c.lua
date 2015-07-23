--//
--||  PROJECT:  Truckjob
--||  AUTHOR:   MasterM
--||  DATE:     July 2015
--\\

local lp = getLocalPlayer()
local isShowing = false
local TruckData = {}


local function setPlayerData(index, value)
outputChatBox("  [DATA] "..tostring(index).." = "..tostring(value))
	TruckData[index] = value
end

local function getPlayerData(index)
	return TruckData[index]
end

addEvent("TruckJob_setPlayerData", true)
addEventHandler("TruckJob_setPlayerData", resourceRoot, setPlayerData)

local function showJobGUI (index)

	if isShowing then return end
	isShowing = true
	showCursor(true)

	local window = guiCreateWindow(403, 231, 251, 311, "", false)
		guiWindowSetSizable(window, false)
	local label_info = guiCreateLabel(10, 29, 231, 120, "Dies ist ein Truckjob", false, window)
	local text
	if getPlayerData("inJob") then
		text = "Job beenden"
	else
		text = "Job annehmen"
	end
	local button_toggle = guiCreateButton(10, 159, 231, 39, text, false, window)
	local button_rent_truck = guiCreateButton(10, 208, 231, 39, "Truck mieten", false, window)
	local button_cancel = guiCreateButton(11, 257, 230, 39, "Abbrechen", false, window)
	
	addEventHandler("onClientGUIClick", button_toggle, function()
		triggerServerEvent("TruckJob_toggle", resourceRoot)
		guiSetEnabled(button_toggle, false)
	end, false)
	
	addEventHandler("onClientGUIClick", button_rent_truck, function()
		triggerServerEvent("TruckJob_rentTruck", resourceRoot, index)
		destroyElement(window)
		isShowing = false
		showCursor(false)
	end, false)	
	
	addEventHandler("onClientGUIClick", button_cancel, function()
		destroyElement(window)
		isShowing = false
		showCursor(false)
	end, false)	
end


addEvent("TruckJob_showJobGUI", true)
addEventHandler("TruckJob_showJobGUI", resourceRoot, showJobGUI)


