--//
--||  PROJECT:  Truckjob
--||  AUTHOR:   MasterM
--||  DATE:     July 2015
--\\


--[[
	Notizen:
	- Anhänger werden beim Scriptstart gespawned
	- Job muss angenommen werden, danach zwei Möglichkeiten
		1. Truck ausleihen (5% Miete pro Fahrt)
		2. eigener Truck (volle Bezahlung)
	- Bezahlung hängt von Distanz und Schaden am Hänger ab
	- Zufallsereignisse wie schnelle Fahrten
	
	BlipID: 51 - Truck
			41 - Waypoint
			52 - Cash
			
]]


local TrailerSpawns, TrailerDestinations, TrailerIDs, JobPickups, TruckSpawnPoints = Truckjob_getData()


local TrailerRespawnDelay = 60000*0.5
local moneyMultiplicator = 2

local Trailers = {}
local Truckers = {}



local function isTruck(vehicle)
	local truckIDs = {
		[403]  = true,
		[514]  = true,
		[515]  = true,
	
	}
	if vehicle and isElement(vehicle) and getElementType(vehicle) == "vehicle" then
		return truckIDs[getElementModel(vehicle)]
	end
	return false
end

local function toggleTrailerBlips(player, state)
	triggerClientEvent(player, "TruckJob_toggleTrailerBlips", resourceRoot, state, Trailers)
end


--//
--||  setTrailerEnabled
--||  parameters:
--||    trailer = the trailer which state should change
--||  returns: void
--\\

local function setTrailerEnabled(trailer, player)
toggleTrailerBlips(player, false)
	if not Trailers[trailer].destinationMarker then
		if not Trailers[trailer].route then
			if not Truckers[player].trailer then
				Truckers[player].trailer = trailer
				Trailers[trailer].trucker = player
				calculateRandomRoute(trailer, player)
				setElementFrozen(trailer, false)
				setVehicleDamageProof(trailer, false)
				setElementHealth(trailer, 1000)
			end
		end
	end
end


--//
--||  setTrailerDisabled
--||  parameters:
--||    trailer = the trailer which state should change
--||  returns: void
--\\

local function setTrailerDisabled(trailer, player)
	if isElement(player) then
		toggleTrailerBlips(player, true)
	end
	if Trailers[trailer].destinationMarker then
		destroyElement(Trailers[trailer].destinationMarker)
		Trailers[trailer].destinationMarker = nil
		Trailers[trailer].trucker = nil
				respawnVehicle(trailer)
		setElementFrozen(trailer, true)
		setVehicleDamageProof(trailer, true)
		if isElement(player) then
			Truckers[player].trailer = nil
		end
	end
end


--//
--||  calculateRandomRoute
--||  parameters:
--||    trailer = the trailer which gets a new route to deliver to
--||  returns: void
--\\

function calculateRandomRoute(trailer, player)
	local name = Trailers[trailer].name
	local randomDestination = math.random(1, #TrailerDestinations[name])
	local trailerX, trailerY, trailerZ = getElementPosition(trailer)
		Trailers[trailer].pos = {trailerX, trailerY, trailerZ}
	local markerX, markerY, markerZ = unpack(TrailerDestinations[name][randomDestination])
	if markerX then
			if getDistanceBetweenPoints3D(trailerX, trailerY, trailerZ, markerX, markerY, markerZ) < 500 then
				return calculateRandomRoute(trailer, player)
			end
		local text = ("Diese Ware muss nach %s (%s)."):format(getZoneName(markerX, markerY, markerZ), getZoneName(markerX, markerY, markerZ, true))
		outputInfo(text, player, "info")
		if math.random(0, 50) == 0 then
			outputInfo("Du bekommst für diese Fahrt das doppelte Geld!", player, "success")
			Trailers[trailer].bonus = true
		end
		Trailers[trailer].destinationMarker = createMarker(markerX, markerY, markerZ)
		local blip = createBlipAttachedTo(Trailers[trailer].destinationMarker, 41)
			setElementVisibleTo(blip, getRootElement(), false)
			if player and isElement(player) then
				setElementVisibleTo(blip, player, true)
			end
		setElementParent(blip, Trailers[trailer].destinationMarker)
		addEventHandler("onMarkerHit", Trailers[trailer].destinationMarker, function(hitElement)
			if hitElement == trailer then
				local player = getVehicleController(trailer)
				if player then
					local trailerHealth = getElementHealth(trailer)
					local startx, starty, startz = unpack(Trailers[trailer].pos)
					local trailerx, trailery, trailerz = getElementPosition(trailer)
					local distance = getDistanceBetweenPoints3D(startx, starty, startz, trailerx, trailery, trailerz)
					local money = math.floor(distance*moneyMultiplicator)
					if Truckers[player].rented then
						money = math.floor((money/100*95)/1000*trailerHealth)
					end
					if Trailers[trailer].bonus then
						money = money*2
						Trailers[trailer].bonus = false
					end
					givePlayerMoney(player, money)
					outputInfo("Du hast "..money.."$ verdient.", player, "success")
				end
				setTrailerDisabled(trailer, player)
			end
		end)
	else
		return calculateRandomRoute(trailer, player)
	end
end


--//
--||  stopJob
--||  parameters:
--||    player = the player who should stop the truck job
--||  returns: void
--\\

local function stopJob(player)
	if type(player) ~= "userdata" then 
		player = source
	end
	
	removeEventHandler("onPlayerWasted", player, stopJob)
	removeEventHandler("onPlayerQuit", player, stopJob)
	
	if Truckers[player].truck then
		local truck = Truckers[player].truck
		local trailer = getVehicleTowedByVehicle(truck)
		
		if trailer then
			setTrailerDisabled(trailer, player)
		end
		
		if Truckers[player].rented then
			destroyElement(truck)
		end
	end
	Truckers[player] = nil
	if isElement(player) then
		toggleTrailerBlips(player, false)
		outputInfo("Du hast den Job beendet.", player, "success")
		triggerClientEvent(player, "TruckJob_setPlayerData", resourceRoot, "inJob", false)
	end
end

addEvent("TruckJob_toggle", true)
addEventHandler("TruckJob_toggle", resourceRoot, function()
	if not Truckers[client] then
		Truckers[client] = {}
		outputInfo("Du hast den Job gestartet.", client, "success")
		toggleTrailerBlips(client, true)
		addEventHandler("onPlayerWasted", client, stopJob)
		addEventHandler("onPlayerQuit", client, stopJob)
		triggerClientEvent(client, "TruckJob_setPlayerData", resourceRoot, "inJob", true)
	else
		stopJob(client)
	end
end)


addEvent("TruckJob_rentTruck", true)
addEventHandler("TruckJob_rentTruck", resourceRoot, function(index)
	if Truckers[client]then
		if not Truckers[client].truck then
			local x, y, z, rz = unpack(TruckSpawnPoints[index])
			local px, py, _ = getElementPosition(client)
			if getDistanceBetweenPoints2D(x, y, px, py) < 200 then
				local truck = createVehicle(514, x, y, z, 0, 0, rz)
					warpPedIntoVehicle(client, truck)
					setVehicleEngineState(truck, true)
					addEventHandler("onVehicleEnter", truck, function(player, seat)
						if seat == 0 and Truckers[player] then
							if Truckers[player].truck ~= truck then
								cancelEvent()
							elseif Truckers[player].jobStopTimer and isTimer(Truckers[player].jobStopTimer) then
								killTimer(Truckers[player].jobStopTimer)
								outputInfo("Willkommen zurück.", player, "success")
							end
						end
					end)
					addEventHandler("onVehicleExit", truck, function(player, seat)
						if seat == 0 and Truckers[player] and Truckers[player].truck == truck then
							if Truckers[player].jobStopTimer and isTimer(Truckers[player].jobStopTimer) then
								killTimer(Truckers[player].jobStopTimer)
							end
							Truckers[player].jobStopTimer = setTimer(stopJob, 30000, 1, player)
							outputInfo("Du hast 30 Sekunden Zeit um wieder in den Truck zu steigen.", player, "warning")
						end
					end)
				
				Truckers[client].truck = truck
				Truckers[client].rented = true
				
				outputInfo("Truck erfolgreich gemietet - viel Spaß!", client, "success")
			end
		else
			outputInfo("Du hast bereits einen Truck!", client, "error")
		end
	else
		outputInfo("Du bist kein Trucker.", client, "error")
	end
end)


--//
--||  spawning loops
--\\

for name, spawns in pairs(TrailerSpawns) do 
	for index,point in ipairs(spawns) do 
		local id = TrailerIDs[name]
		local trailer = createVehicle(id, point[1], point[2], point[3], 0, 0, point[4])
		Trailers[trailer] = {}
		Trailers[trailer].index = index
		Trailers[trailer].name = name
		setVehicleDamageProof(trailer, true)
		setVehicleOverrideLights ( trailer, 1 )
		setElementFrozen(trailer, true)
		toggleVehicleRespawn(trailer, true)
		setVehicleIdleRespawnDelay(trailer, TrailerRespawnDelay)
		setVehicleRespawnPosition(trailer, point[1], point[2], point[3], 0, 0, point[4])
		addEventHandler("onTrailerAttach", trailer, function(truck)
			local player = getVehicleController(truck)
			if player then
			if not Truckers[player] or (Truckers[player].trailer and Truckers[player].trailer ~= source) then 
				outputInfo("Du darfst diesen Anhänger nicht nehmen.", player, "error")
				detachTrailerFromVehicle(truck)  
				setElementPosition(trailer, 0, 0, 0)
				setTimer(function() respawnVehicle(trailer) end, 5000, 1)
			return false end
			
				if not Truckers[player].truck then
					if isTruck(truck) then
						Truckers[player].truck = truck
					end
				end
				if Truckers[player].truck == truck then
					setTrailerEnabled(source, player)					
				end	
			end	
		end)
		addEventHandler("onVehicleRespawn", source, function()
			if not getVehicleController(source) then
				setTrailerDisabled(source, Trailers[source].trucker)
			end
		end)
		addEventHandler("onTrailerDetach", trailer, function(truck)
			local player = getVehicleController(truck)
			if player then
			if not Truckers[player] then return false end
				if Truckers[player].truck == truck then
					outputInfo("Du musst den Anhänger innerhalb von "..(TrailerRespawnDelay/60000).." Minuten wieder anhängen.", player, "warning")	
				end	
			end	
		end)
	end
end

for index, point in pairs(JobPickups) do
	local pick = createPickup(point[1], point[2], point[3], 3, 1274, 0)
	local blip = createBlip(point[1], point[2], point[3], 52)
		setElementParent(blip, pick)
	addEventHandler("onPickupHit", pick, function(hitElement)
			if not getPedOccupiedVehicle(hitElement) then
				triggerClientEvent(hitElement, "TruckJob_showJobGUI", resourceRoot, index)
			end
	end)
end


--//
--||  DEBUG
--\\
--[[
local function getPos(player)
	local veh = getPedOccupiedVehicle(player)
	local x,y,z = getElementPosition(veh)
	local _,_,rz = getElementRotation(veh)
	x, y, z, rz = math.floor(x*1000)/1000, math.floor(y*1000)/1000, math.floor(z*1000)/1000, math.floor(rz*1000)/1000 
	outputChatBox(("{%s, %s, %s, %s},"):format(x,y,z,rz))


end
addCommandHandler("pos", getPos)
outputDebugString("restart")
]]




function render()




end
