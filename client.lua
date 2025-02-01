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

ESX = exports['es_extended']:getSharedObject()

Citizen.CreateThread(function()
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
            ESX.ShowFloatingHelpNotification("Presiona ~g~[E]~w~ para hablar con Manuel", vector3(-1178.2655, -891.5996, 13.7571 + 1.0))
        end

        if dist < 3.0 then
            if IsControlJustReleased(0, 38) then
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

function iniciarTrabajo()
    trabajando = true
    ESX.ShowNotification("Aquí tienes tu moto, ahora ve a entregar los pedidos")

    RequestModel(GetHashKey("110i2019"))
    while not HasModelLoaded(GetHashKey("110i2019")) do
        Wait(1)
    end

    local playerCoords = GetEntityCoords(PlayerPedId())
    moto = CreateVehicle(GetHashKey("110i2019"), playerCoords.x + 2.0, playerCoords.y, playerCoords.z, 0.0, true, false)
    SetVehicleNumberPlateText(moto, "PEDIDOSYA")
    SetVehicleOnGroundProperly(moto)
    asignarEntrega()
end

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

    SetNewWaypoint(punto.x, punto.y)

    RequestModel(GetHashKey("a_m_m_farmer_01"))
    while not HasModelLoaded(GetHashKey("a_m_m_farmer_01")) do
        Wait(1)
    end

    local pedEntrega = CreatePed(4, GetHashKey("a_m_m_farmer_01"), punto.x, punto.y, punto.z, 0.0, false, true)
    SetEntityInvincible(pedEntrega, true)
    FreezeEntityPosition(pedEntrega, true)
    SetBlockingOfNonTemporaryEvents(pedEntrega, true)

    Citizen.CreateThread(function()
        while trabajando do
            local playerCoords = GetEntityCoords(PlayerPedId())
            local dist = #(playerCoords - vector3(punto.x, punto.y, punto.z))

            local playerPed = PlayerPedId()
            local vehicle = GetVehiclePedIsIn(playerPed, false)

            if dist < 3.0 then
                if vehicle ~= 0 then
                    ESX.ShowFloatingHelpNotification("¡Debes bajarte de la moto para entregar el pedido!", vector3(punto.x, punto.y, punto.z + 1.0))
                else
                    ESX.ShowFloatingHelpNotification("Presiona ~g~[E]~w~ para entregar el pedido", vector3(punto.x, punto.y, punto.z + 1.0))
                end

                if IsControlJustReleased(0, 38) then
                    if vehicle == 0 then
                        iniciarSkillCheck()
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

function iniciarSkillCheck()
    -- Llamamos al skillcheck de ox_lib
    local result = lib.skillcheck({
        label = "Adivina la letra correcta!",
        items = {"A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"},
    })

    -- Si el jugador pasa el skill check
    if result then
        ESX.ShowNotification("¡Adivinaste la letra correcta! ¡Recibiste el pago completo!")
        TriggerServerEvent('pedidosYa:pagar', math.random(60000, 100000)) -- Pago completo
    else
        ESX.ShowNotification("¡Fallaste! ¡Tu pago ha sido reducido!")
        TriggerServerEvent('pedidosYa:pagar', math.random(42000, 70000)) -- Pago reducido
    end
end
