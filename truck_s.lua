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


local TrailerSpawns, TrailerDestinations, TrailerIDs, JobPickups, TruckSpawnPoints = Truckjob_getData()


local Trailers = {}
local Truckers = {}

for name, spawns in pairs(TrailerSpawns) do 
	for index,point in ipairs(spawns) do 
		local id = TrailerIDs[name]
		local trailer = createVehicle(id, point[1], point[2], point[3], 0, 0, point[4])
		Trailers[trailer] = {}
		Trailers[trailer].index = index
		Trailers[trailer].name = name
		--createBlipAttachedTo(trailer)
		setVehicleDamageProof(trailer, true)
		setElementFrozen(trailer, true)
		addEventHandler("onTrailerAttach", trailer, function(truck)
			local player = getVehicleController(truck)
			if player then
				if Truckers[player].truck == truck then
					if not Trailers[trailer].route then
						calculateRandomRoute(trailer)
					end			
				end	
			end	
		end)
	end
end

for index, point in pairs(JobPickups) do
	local pick = createPickup(point[1], point[2], point[3], 3, 1274, 0)
	addEventHandler("onPickupHit", pick, function(hitElement)
			if not getPedOccupiedVehicle(hitElement) then
				triggerClientEvent(hitElement, "TruckJob_showJobGUI", resourceRoot, index)
			end
	end)
end


addEvent("TruckJob_toggle", true)
addEventHandler("TruckJob_toggle", resourceRoot, function()
	if not Truckers[client] then
		Truckers[client] = {}
		outputChatBox("Job gestartet", client)
		triggerClientEvent(client, "TruckJob_setPlayerData", resourceRoot, "inJob", true)
	else
		Truckers[client] = nil
		outputChatBox("Job beendet", client)
		triggerClientEvent(client, "TruckJob_setPlayerData", resourceRoot, "inJob", false)
	
	end
end)


addEvent("TruckJob_rentTruck", true)
addEventHandler("TruckJob_rentTruck", resourceRoot, function(index)
	if Truckers[client] then
		local x, y, z, rz = unpack(TruckSpawnPoints[index])
		local px, py, _ = getElementPosition(client)
		if getDistanceBetweenPoints2D(x, y, px, py) < 200 then
			local truck = createVehicle(514, x, y, z, 0, 0, rz)
				warpPedIntoVehicle(client, truck)
				setVehicleEngineState(truck, true)
				addEventHandler("onVehicleStartEnter", truck, function(player, seat)
					if seat == 0 and Truckers[player] and Truckers[player].truck ~= truck then
						cancelEvent()
					end
				end)
			
			Truckers[client].truck = truck
			
			outputChatBox("Truck gemietet", client)
		end
	else
		outputChatBox("Du bist kein Trucker", client)
	end
end)



function calculateRandomRoute(trailer)
	local name = Trailers[trailer].name
	local randomDestination = math.random(1, #TrailerDestinations[name])
	Trailers[trailer].destinationMarker = createMarker(unpack(TrailerDestinations[name][randomDestination]))
	createBlipAttachedTo(Trailers[trailer].destinationMarker)

end


--[[
local function getPos(player)
	local veh = getPedOccupiedVehicle(player)
	local x,y,z = getElementPosition(veh)
	local _,_,rz = getElementRotation(veh)
	x, y, z, rz = math.floor(x*1000)/1000, math.floor(y*1000)/1000, math.floor(z*1000)/1000, math.floor(rz*1000)/1000 
	outputChatBox(("{%s, %s, %s, %s},"):format(x,y,z,rz))


end
addCommandHandler("pos", getPos)
]]
