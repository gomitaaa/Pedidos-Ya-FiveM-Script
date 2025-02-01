ESX = nil

-- Obtener ESX
ESX = exports['es_extended']:getSharedObject()

RegisterNetEvent('pedidosYa:comenzarEntrega')
AddEventHandler('pedidosYa:comenzarEntrega', function()
    local pagoNormal = math.random(60000, 100000)  -- Pago entre 60,000 y 100,000

    -- Pago completo
    TriggerClientEvent('esx:showNotification', source, '¡Pedido entregado! Recibiste el pago completo de $' .. pagoNormal)

    -- Pagar al jugador el monto completo
    TriggerServerEvent('pedidosYa:pagar', pagoNormal)
end)
