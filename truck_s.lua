--//
--||  PROJECT:  Truckjob
--||  AUTHOR:   MasterM
--||  DATE:     July 2015
--\\

--//
--[[
	- Anhänger werden beim Scriptstart gespawned
	- Job muss angenommen werden, danach zwei Möglichkeiten
		1. Truck ausleihen (5% Miete pro Fahrt)
		2. eigener Truck (volle Bezahlung)
	- Bezahlung hängt von Distanz und Schaden am Hänger ab
	- Zufallsereignisse wie schnelle Fahrten
]]
--\\


local TrailerSpawns, TrailerDestinations, TrailerIDs, JobPickups = Truckjob_getData()


local Trailers = {}
local Truckers = {}

for name, spawns in pairs(TrailerSpawns) do 
	for index,point in ipairs(spawns) do 
		local id = TrailerIDs[name]
		local trailer = createVehicle(id, point[1], point[2], point[3], 0, 0, point[4])
		Trailers[trailer] = {}
		Trailers[trailer].index = index
		Trailers[trailer].name = name
		createBlipAttachedTo(trailer)
	end
end

for index, point in pairs(JobPickups) do
	local pick = createPickup(point[1], point[2], point[3], 3, 1274, 0)
	addEventHandler("onPickupHit", pick, function(hitElement)
			if not getPedOccupiedVehicle(hitElement) then
				triggerClientEvent(hitElement, "TruckJob_showJobGUI", resourceRoot)
			end
	end)
end


addEvent("TruckJob_start", true)
addEventHandler("TruckJob_start", resourceRoot, function()
	if not Truckers[client] then
		Truckers[client] = {}
		outputChatBox("Job gestartet")
	end
end)
