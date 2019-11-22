ESX 						   = nil
local CopsConnected       	   = 0
local PlayersHarvestingKoda    = {}
local PlayersTransformingKoda  = {}
local PlayersSellingKoda       = {}

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

function CountCops()
	local xPlayers = ESX.GetPlayers()

	CopsConnected = 0

	for i=1, #xPlayers, 1 do
		local xPlayer = ESX.GetPlayerFromId(xPlayers[i])
		if xPlayer.job.name == 'police' then
			CopsConnected = CopsConnected + 1
		end
	end

	SetTimeout(120 * 1000, CountCops)
end

CountCops()

local function HarvestKoda(source)

	SetTimeout(Config.TimeToFarm, function()
		if PlayersHarvestingKoda[source] then
			local xPlayer = ESX.GetPlayerFromId(source)
			local koda = xPlayer.getInventoryItem('wood1')

			if koda.limit ~= -1 and koda.count >= koda.limit then
				TriggerClientEvent('esx:showNotification', source, _U('mochila_full'))
			else
				xPlayer.addInventoryItem('wood1', 1)
				HarvestKoda(source)
			end
		end
	end)
end

RegisterServerEvent('esx_farmholz:startHarvestKoda')
AddEventHandler('esx_farmholz:startHarvestKoda', function()
	local _source = source

	if not PlayersHarvestingKoda[_source] then
		PlayersHarvestingKoda[_source] = true

		TriggerClientEvent('esx:showNotification', _source, _U('pegar_laranjas'))
		HarvestKoda(_source)
	else
		print(('esx_farmholz: %s attempted to exploit the marker!'):format(GetPlayerIdentifiers(_source)[1]))
	end
end)

RegisterServerEvent('esx_farmholz:stopHarvestKoda')
AddEventHandler('esx_farmholz:stopHarvestKoda', function()
	local _source = source

	PlayersHarvestingKoda[_source] = false
end)

local function TransformKoda(source)

	SetTimeout(Config.TimeToProcess, function()
		if PlayersTransformingKoda[source] then
			local xPlayer = ESX.GetPlayerFromId(source)
			local kodaQuantity = xPlayer.getInventoryItem('wood1').count
			local pooch = xPlayer.getInventoryItem('wood2')

			if pooch.limit ~= -1 and pooch.count >= pooch.limit then
				TriggerClientEvent('esx:showNotification', source, _U('nao_tens_laranjas_suficientes'))
			elseif kodaQuantity < 5 then
				TriggerClientEvent('esx:showNotification', source, _U('nao_tens_mais_laranjas'))
			else
				xPlayer.removeInventoryItem('wood1', 2)
				xPlayer.addInventoryItem('wood2', 1)

				TransformKoda(source)
			end
		end
	end)
end

RegisterServerEvent('esx_farmholz:startTransformKoda')
AddEventHandler('esx_farmholz:startTransformKoda', function()
	local _source = source

	if not PlayersTransformingKoda[_source] then
		PlayersTransformingKoda[_source] = true

		TriggerClientEvent('esx:showNotification', _source, _U('transformar_wood2'))
		TransformKoda(_source)
	else
		print(('esx_farmholz: %s attempted to exploit the marker!'):format(GetPlayerIdentifiers(_source)[1]))
	end
end)

RegisterServerEvent('esx_farmholz:stopTransformKoda')
AddEventHandler('esx_farmholz:stopTransformKoda', function()
	local _source = source

	PlayersTransformingKoda[_source] = false
end)

local function SellKoda(source)

	SetTimeout(Config.TimeToSell, function()
		if PlayersSellingKoda[source] then
			local xPlayer = ESX.GetPlayerFromId(source)
			local poochQuantity = xPlayer.getInventoryItem('wood2').count

			if poochQuantity == 0 then
				TriggerClientEvent('esx:showNotification', source, _U('nao_tens_wood2'))
			else
				xPlayer.removeInventoryItem('wood2', 1)
				if CopsConnected == 0 then
					xPlayer.addAccountMoney('bank', 150)
					TriggerClientEvent('esx:showNotification', source, _U('vendeste_sumo'))
				elseif CopsConnected >= 0 then
					xPlayer.addAccountMoney('bank', 150)
					TriggerClientEvent('esx:showNotification', source, _U('vendeste_sumo'))
				end

				SellKoda(source)
			end
		end
	end)
end

RegisterServerEvent('esx_farmholz:startSellKoda')
AddEventHandler('esx_farmholz:startSellKoda', function()
	local _source = source

	if not PlayersSellingKoda[_source] then
		PlayersSellingKoda[_source] = true

		TriggerClientEvent('esx:showNotification', _source, _U('venda_do_sumo'))
		SellKoda(_source)
	else
		print(('esx_farmholz: %s attempted to exploit the marker!'):format(GetPlayerIdentifiers(_source)[1]))
	end
end)

RegisterServerEvent('esx_farmholz:stopSellKoda')
AddEventHandler('esx_farmholz:stopSellKoda', function()
	local _source = source

	PlayersSellingKoda[_source] = false
end)

RegisterServerEvent('esx_farmholz:GetUserInventory')
AddEventHandler('esx_farmholz:GetUserInventory', function(currentZone)
	local _source = source
	local xPlayer = ESX.GetPlayerFromId(_source)
	TriggerClientEvent('esx_farmholz:ReturnInventory',
		_source,
		xPlayer.getInventoryItem('wood1').count,
		xPlayer.getInventoryItem('wood2').count,
		xPlayer.job.name,
		currentZone
	)
end)

ESX.RegisterUsableItem('wood1', function(source)
	local _source = source
	local xPlayer = ESX.GetPlayerFromId(_source)

	xPlayer.removeInventoryItem('wood1', 1)

	TriggerClientEvent('esx_farmholz:onPot', _source)
	TriggerClientEvent('esx:showNotification', _source, _U('used_one_koda'))
end)
