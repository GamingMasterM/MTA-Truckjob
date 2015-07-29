--//
--||  PROJECT:  Truckjob
--||  AUTHOR:   MasterM
--||  DATE:     July 2015
--\\

local lp = getLocalPlayer()
local isShowing = false
local TruckData = {}


local function setPlayerData(index, value)
--outputChatBox("  [DATA] "..tostring(index).." = "..tostring(value))
	TruckData[index] = value
end

addEvent("TruckJob_setPlayerData", true)
addEventHandler("TruckJob_setPlayerData", resourceRoot, setPlayerData)

local function getPlayerData(index)
	return TruckData[index]
end

local Bliplist = {}

local function toggleBlips(state, Trailers)
	if state then
		Bliplist = {}
		for i,v in pairs(Trailers) do 
			if not v.destinationMarker then
				local tx,ty,tz = getElementPosition(i)
				local blip = createBlip(tx, ty, tz, 51)
				table.insert(Bliplist, blip)	
			end
		end
	else 
		if Bliplist then
			for i,v in pairs(Bliplist) do
				if isElement(v) then
					destroyElement(v)
				end
			end	
		end
	
	end
end

addEvent("TruckJob_toggleTrailerBlips", true)
addEventHandler("TruckJob_toggleTrailerBlips", resourceRoot, toggleBlips)


local function showJobGUI (index)

	if isShowing then return end
	isShowing = true
	showCursor(true)

	local window = guiCreateWindow(403, 231, 251, 311, "Trucker", false)
		guiWindowSetSizable(window, false)
	local label_info = guiCreateMemo(10, 29, 231, 120, "Starte noch heute eine aufregende Karriere als Trucker in San Andreas! Alles, was es dazu braucht sind etwas Mut und die Fähigkeit, auf den 'Annehmen'-Knopf zu drücken, also worauf wartest du noch!? \nPS: Du hast keinen eigenen Truck? Dann leih dir einen bei uns aus, dies kostet aber pro Fahrt 10% deines Einkommens.", false, window)
		guiMemoSetReadOnly(label_info, true)
	local text
	if getPlayerData("inJob") then
		text = "Job beenden"
	else
		text = "Annehmen!"
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


