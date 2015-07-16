--//
--||  PROJECT:  Truckjob
--||  AUTHOR:   MasterM
--||  DATE:     July 2015
--\\

local lp = getLocalPlayer()
local isShowing = false

local function showJobGUI ()

	if isShowing then return end
	isShowing = true
	showCursor(true)

	local window = guiCreateWindow(403, 231, 251, 311, "", false)
		guiWindowSetSizable(window, false)
	local label_info = guiCreateLabel(10, 29, 231, 120, "Dies ist ein Truckjob", false, window)
	local button_start = guiCreateButton(10, 159, 231, 39, "Job annehmen", false, window)
	local button_rent_truck = guiCreateButton(10, 208, 231, 39, "Truck mieten", false, window)
	local button_cancel = guiCreateButton(11, 257, 230, 39, "Abbrechen", false, window)
	
	addEventHandler("onClientGUIClick", button_start, function()
		triggerServerEvent("TruckJob_start", resourceRoot)
		guiSetEnabled(button_start, false)
	end, false)
	
	addEventHandler("onClientGUIClick", button_cancel, function()
		destroyElement(window)
		isShowing = false
		showCursor(false)
	end, false)	
end


addEvent("TruckJob_showJobGUI", true)
addEventHandler("TruckJob_showJobGUI", resourceRoot, showJobGUI)