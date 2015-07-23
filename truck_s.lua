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


local TrailerRespawnDelay = 60000*2
local moneyMultiplicator = 2

local Trailers = {}
local Truckers = {}


local function setTrailerEnabled(trailer)
	if not Trailers[trailer].destinationMarker then
		if not Trailers[trailer].route then
			calculateRandomRoute(trailer)
			setElementFrozen(trailer, false)
			setVehicleDamageProof(trailer, false)
		end
	end
end


local function setTrailerDisabled(trailer)
	if Trailers[trailer].destinationMarker then
		respawnVehicle(trailer)
		destroyElement(Trailers[trailer].destinationMarker)
		Trailers[trailer].destinationMarker = nil
		setElementFrozen(trailer, true)
		setVehicleDamageProof(trailer, true)
	end
end

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
		setVehicleIdleRespawnDelay(trailer, TrailerRespawnDelay)
		setVehicleRespawnPosition(trailer, point[1], point[2], point[3], 0, 0, point[4])
		addEventHandler("onTrailerAttach", trailer, function(truck)
			local player = getVehicleController(truck)
			if player then
				if Truckers[player].truck == truck then
					setTrailerEnabled(trailer)			
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



local function stopJob(player)
	if Truckers[player].rented and Truckers[player].truck then
		local truck = Truckers[player].truck
		local trailer = getVehicleTowedByVehicle(truck)
		if trailer then
			setTrailerDisabled(trailer)
		end
		destroyElement(truck)	
	end
	Truckers[player] = nil
	outputChatBox("Job beendet", player)
	triggerClientEvent(player, "TruckJob_setPlayerData", resourceRoot, "inJob", false)
end

addEvent("TruckJob_toggle", true)
addEventHandler("TruckJob_toggle", resourceRoot, function()
	if not Truckers[client] then
		Truckers[client] = {}
		outputChatBox("Job gestartet", client)
		triggerClientEvent(client, "TruckJob_setPlayerData", resourceRoot, "inJob", true)
	else
		stopJob(player)
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
					if seat == 0 and Truckers[player] then
						if Truckers[player].truck ~= truck then
							cancelEvent()
						elseif Truckers[player].jobStopTimer and isTimer(Truckers[player].jobStopTimer) then
							killTimer(Truckers[player].jobStopTimer)
							outputChatBox("Willkommen zurück.", player)
						end
					end
				end)
				addEventHandler("onVehicleExit", truck, function(player, seat)
					if seat == 0 and Truckers[player] and Truckers[player].truck == truck then
						if Truckers[player].jobStopTimer and isTimer(Truckers[player].jobStopTimer) then
							killTimer(Truckers[player].jobStopTimer)
						end
						Truckers[player].jobStopTimer = setTimer(stopJob, 3000, 1, player)
						outputChatBox("Du hast 30 Sekunden Zeit um wieder in den Truck zu steigen.", player)
					end
				end)
			
			Truckers[client].truck = truck
			Truckers[client].rented = true
			
			outputChatBox("Truck gemietet", client)
		end
	else
		outputChatBox("Du bist kein Trucker", client)
	end
end)



function calculateRandomRoute(trailer)
	local name = Trailers[trailer].name
	local randomDestination = math.random(1, #TrailerDestinations[name])
	Trailers[trailer].pos = {unpack({getElementPosition(trailer)})}
	Trailers[trailer].destinationMarker = createMarker(unpack(TrailerDestinations[name][randomDestination]))
	createBlipAttachedTo(Trailers[trailer].destinationMarker)
	addEventHandler("onMarkerHit", Trailers[trailer].destinationMarker, function(hitElement)
		if hitElement == trailer then
			local player = getVehicleController(trailer)
			if player then
				local startx, starty, startz = unpack(Trailers[trailer].pos)
				local trailerx, trailery, trailerz = getElementPosition(trailer)
				local distance = getDistanceBetweenPoints3D(startx, starty, startz, trailerx, trailery, trailerz)
				local money = math.floor(distance*moneyMultiplicator)
				givePlayerMoney(player, money)
				outputChatBox("Du hast "..money.."$ verdient.")
			end
			setTrailerDisabled(trailer)
		end
	end)
end



local function getPos(player)
	local veh = getPedOccupiedVehicle(player)
	local x,y,z = getElementPosition(veh)
	local _,_,rz = getElementRotation(veh)
	x, y, z, rz = math.floor(x*1000)/1000, math.floor(y*1000)/1000, math.floor(z*1000)/1000, math.floor(rz*1000)/1000 
	outputChatBox(("{%s, %s, %s, %s},"):format(x,y,z,rz))


end
addCommandHandler("pos", getPos)

