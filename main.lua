-- DisableAutoPickup v1.0.1
-- SmoothSpatula

mods["RoRRModdingToolkit-RoRR_Modding_Toolkit"].auto(true)
mods["SmoothSpatula-TomlHelper"].auto()

local params = {
    pickup_key = 80
}

params = Toml.config_update(_ENV["!guid"], params)


local players_pickup = {}
local self_pickup = false

function init()
    local packetUpdatePickup = Packet.new()

    packetUpdatePickup:onReceived(function(msg)
        local m_id = msg:read_uint()
        local value = msg:read_uint()
        if value == 1 then
            players_pickup[m_id] = true
        else
            players_pickup[m_id] = false
        end
        if gm._mod_net_isHost() then -- send back to all clients
            local msg_back = packetUpdatePickup:message_begin()
            msg_back:write_uint(m_id) -- could replace with instance
            msg_back:write_uint(value)
            msg_back:send_to_all()
        end 
    end)

	gui.add_to_menu_bar(function()
        local isChanged, keybind_value = ImGui.Hotkey("Pickup Keybind", params['pickup_key'])
        if isChanged then
            params['pickup_key'] = keybind_value
            Toml.save_cfg(_ENV["!guid"], params)
        end
    end)

    gm.pre_script_hook(gm.constants.__lf_pPickup_step_collide_item, function(self, other, result, args)
        if (not players_pickup[args[2].value.m_id]) and args[1].value.tier ~= Item.TIER.equipment then return false end
    end)

    gui.add_always_draw_imgui(function()
        if not gm.variable_global_get("__run_exists") then return end
        local updateState = false
        if ImGui.IsKeyDown(params['pickup_key']) then
            if self_pickup == false then
                self_pickup = true
                updateState = true
            end
        else
            if self_pickup == true then
                self_pickup = false
                updateState = true
            end
        end
        if updateState then
            local player = Player.get_client()
            players_pickup[player.m_id] = self_pickup
            if gm._mod_net_isOnline() then
                local value = 1
                if not self_pickup then
                    value = 0
                end
                local msg = packetUpdatePickup:message_begin()
                
                msg:write_uint(player.m_id) -- could replace with instance
                msg:write_uint(1) -- if the target is invalid, the wurm is inferred to not be firing
                if gm._mod_net_isHost() then
                    msg:send_to_all()
                else
                    msg:send_to_host()
                end
            end
        end
    end)
end

Initialize(init)
