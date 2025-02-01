ESX = nil
ESX = exports['es_extended']:getSharedObject()

RegisterNetEvent('pedidosYa:pagar')
AddEventHandler('pedidosYa:pagar', function(monto)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    xPlayer.addMoney(monto)  -- Paga el monto al jugador
end)
