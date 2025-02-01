ESX = nil
local trabajando = false
local moto = nil
local blipEntrega = nil
local pedManuel = nil
local puntosEntrega = {
    {x = -757.6675, y = -709.5873, z = 28.5139},  
    {x = -1112.9193, y = -903.3022, z = 2.5660},
    {x = -601.3831, y = -930.1242, z = 22.9219},
    {x = -309.7980, y = -825.5588, z = 31.3975},
    {x = -59.3297, y = -616.8031, z = 36.3544},
    {x = -27.2369, y = -347.2522, z = 43.9581},
}

-- Obtener ESX
ESX = exports['es_extended']:getSharedObject()

Citizen.CreateThread(function()
    -- Crear blip y ped Manuel
    local blip = AddBlipForCoord(-1178.2655, -891.5996, 13.7571)
    SetBlipSprite(blip, 525)
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, 0.6)
    SetBlipColour(blip, 4)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Sede de Pedidos Ya")
    EndTextCommandSetBlipName(blip)

    RequestModel(GetHashKey("s_m_m_linecook"))
    while not HasModelLoaded(GetHashKey("s_m_m_linecook")) do
        Wait(1)
    end

    pedManuel = CreatePed(4, GetHashKey("s_m_m_linecook"), -1178.2655, -891.5996, 13.7571 - 1.0, 303.9326, false, true)
    SetEntityHeading(pedManuel, 303.9326)
    FreezeEntityPosition(pedManuel, true)
    SetEntityInvincible(pedManuel, true)
    SetBlockingOfNonTemporaryEvents(pedManuel, true)
end)

Citizen.CreateThread(function()
    while true do
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local dist = #(playerCoords - vector3(-1178.2655, -891.5996, 13.7571))

        if dist < 5.0 then
            -- Usar ESX para mostrar la notificación flotante
            ESX.ShowFloatingHelpNotification("Presiona ~g~[E]~w~ para hablar con Manuel", vector3(-1178.2655, -891.5996, 13.7571 + 1.0)) -- Ajuste en la altura
        end

        if dist < 3.0 then
            if IsControlJustReleased(0, 38) then -- 38 es la tecla E
                if not trabajando then
                    iniciarTrabajo()
                else
                    terminarTrabajo()
                end
            end
        end

        Wait(0)
    end
end)

-- Función para iniciar el trabajo
function iniciarTrabajo()
    trabajando = true
    ESX.ShowNotification("Aquí tienes tu moto, ahora ve a entregar los pedidos")
    
    -- Crear moto
    RequestModel(GetHashKey("110i2019"))
    while not HasModelLoaded(GetHashKey("110i2019")) do
        Wait(1)
    end

    local playerCoords = GetEntityCoords(PlayerPedId())
    moto = CreateVehicle(GetHashKey("110i2019"), playerCoords.x + 2.0, playerCoords.y, playerCoords.z, 0.0, true, false)
    SetVehicleNumberPlateText(moto, "PEDIDOSYA") -- Opcional, asignar matrícula a la moto
    SetVehicleOnGroundProperly(moto)
    asignarEntrega()
end

-- Función para terminar el trabajo
function terminarTrabajo()
    trabajando = false
    if moto then
        DeleteVehicle(moto)
        moto = nil
    end
    if blipEntrega then
        RemoveBlip(blipEntrega)
        blipEntrega = nil
    end
    ESX.ShowNotification("Has dejado de trabajar.")
end

-- Función para asignar una entrega
function asignarEntrega()
    if blipEntrega then
        RemoveBlip(blipEntrega)
    end

    local punto = puntosEntrega[math.random(1, #puntosEntrega)]
    blipEntrega = AddBlipForCoord(punto.x, punto.y, punto.z)
    SetBlipSprite(blipEntrega, 817)
    SetBlipColour(blipEntrega, 4)
    SetBlipScale(blipEntrega, 0.9)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Entrega de Pedido")
    EndTextCommandSetBlipName(blipEntrega)

    -- Marcar waypoint amarillo
    SetNewWaypoint(punto.x, punto.y)

    -- Crear ped en el punto de entrega
    RequestModel(GetHashKey("a_m_m_farmer_01"))
    while not HasModelLoaded(GetHashKey("a_m_m_farmer_01")) do
        Wait(1)
    end

    local pedEntrega = CreatePed(4, GetHashKey("a_m_m_farmer_01"), punto.x, punto.y, punto.z, 0.0, false, true)
    SetEntityInvincible(pedEntrega, true)
    FreezeEntityPosition(pedEntrega, true)
    SetBlockingOfNonTemporaryEvents(pedEntrega, true)

    -- Detectar interacción en el punto de entrega
    Citizen.CreateThread(function()
        while trabajando do
            local playerCoords = GetEntityCoords(PlayerPedId())
            local dist = #(playerCoords - vector3(punto.x, punto.y, punto.z))

            -- Verificar si el jugador está dentro de un vehículo
            local playerPed = PlayerPedId()
            local vehicle = GetVehiclePedIsIn(playerPed, false)

            if dist < 3.0 then
                -- Mostrar la notificación flotante
                if vehicle ~= 0 then
                    ESX.ShowFloatingHelpNotification("¡Debes bajarte de la moto para entregar el pedido!", vector3(punto.x, punto.y, punto.z + 1.0))
                else
                    ESX.ShowFloatingHelpNotification("Presiona ~g~[E]~w~ para entregar el pedido", vector3(punto.x, punto.y, punto.z + 1.0))
                end

                if IsControlJustReleased(0, 38) then
                    if vehicle == 0 then
                        -- Notificación de entrega
                        TriggerServerEvent('pedidosya:pay') -- Llama al evento del servidor
                        ESX.ShowNotification("¡Pedido entregado!")
                        DeletePed(pedEntrega)
                        asignarEntrega()
                        break
                    else
                        ESX.ShowNotification("¡Debes bajarte de la moto primero!")
                    end
                end
            end
            Wait(0)
        end
    end)
end
