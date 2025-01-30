local Tunnel = module("vrp","lib/Tunnel")
local Proxy = module("vrp","lib/Proxy")

vRP = Proxy.getInterface("vRP")
vRPclient = Tunnel.getInterface("vRP")

src = {}
Tunnel.bindInterface("nation_bennys",src)
Proxy.addInterface("nation_bennys",src)

vCLIENT = Tunnel.getInterface("nation_bennys")

local using_bennys = {}
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- OUTROS
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- function src.checkPermission()
--     local source = source
--     local user_id = vRP.getUserId(source)
-- 	if vRP.hasPermission(user_id, "perm.tunar") then   --permissão que as duas mec tem que ter
--         return true
--     end
-- end

function src.checkPermission(mecanica)
    local source = source
    local user_id = vRP.getUserId(source)

    if not user_id then return false end -- Garante que o usuário seja válido

    local perms = config.permission[mecanica] -- Obtém as permissões associadas à mecânica especificada

    if perms then
        for _, permission in pairs(perms) do
            if vRP.hasPermission(user_id, permission) then
                return true
            end
        end
    end

    return false
end




function src.getSavedMods(vehplate,vehname)
    local vehuser = vRP.getUserByRegistration(vehplate)
    if vehuser then
        local rows = vRP.query("vRP/get_tunagem", {user_id = vehuser, veiculo = vehname})
		if rows[1] then
        	return json.decode(rows[1].tunagem or {}) or {}
		end
    end
    return false
end

function src.checkPayment(amount)
    local source = source
    local user_id = vRP.getUserId(source)
	
	if amount == nil or parseInt(amount) <= 0 then
	   amount = 5000
	end

    if vRP.tryFullPayment(user_id, parseInt(amount)) then
        TriggerClientEvent("Notify",source,"sucesso","Modificações aplicadas com <b>sucesso</b><br >Você pagou <b>$ "..vRP.format(tonumber(amount)).."<b>.", 5)
        return true
    else
        TriggerClientEvent("Notify",source,"negado","Você não possui dinheiro suficiente.", 5)
        return false
    end 
	
end

function src.repairVehicle(vehicle, damage)
    TriggerEvent("tryreparar", vehicle)
    return true
end

function src.removeVehicle(vehicle)
    using_bennys[vehicle] = nil
    return true
end

function src.checkVehicle(vehicle)
    if using_bennys[vehicle] then
        return false
    end
    using_bennys[vehicle] = true
    return true
end

function src.checkTuningVehicle()
    local source = source
	local  mPlaca,mName,mNet,mPortaMalas,mPrice,mLock = vRPclient.ModelName(source,7)
	local puser_id = vRP.getUserByRegistration(mPlaca)
	if mPlaca then
		local rows = vRP.query("vRP/get_portaMalas",{ user_id = puser_id, veiculo = mName })
		if #rows > 0 then
			return true
		end
	end
end

function src.saveVehicle(vehname, vehplate, custom)
    local vehuser = vRP.getUserByRegistration(vehplate)
    if vehuser then
		vRP.execute("vRP/update_tuning",{ user_id = vehuser, veiculo = vehname, tunagem = json.encode(custom) })
    end
end

RegisterServerEvent("nation:syncApplyMods")
AddEventHandler("nation:syncApplyMods",function(vehicle_tuning,vehicle)
    TriggerClientEvent("nation:applymods_sync",-1,vehicle_tuning,vehicle)
end)

-----------------------------------------------------------------------------------------------------------------------------------------
-- TOW
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterServerEvent("trytow")
AddEventHandler("trytow",function(nveh,rveh)
	TriggerClientEvent("synctow",-1,nveh,rveh)
end)


RegisterServerEvent("bennys:checkPermission")
AddEventHandler("bennys:checkPermission", function(mecanica)
    local source = source
    if src.checkPermission(mecanica) then
        TriggerClientEvent("bennys:openMenu", source) -- Abre o menu de tunagem
    else
        TriggerClientEvent("bennys:notify", source, "Você não tem permissão para tunar nesta mecânica.")
    end
end)
