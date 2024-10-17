-- DisableAutoPickup v1.0.0
-- SmoothSpatula

mods["RoRRModdingToolkit-RoRR_Modding_Toolkit"].auto()

local params = {
    pickup_key = 80
}

mods.on_all_mods_loaded(function() for k, v in pairs(mods) do if type(v) == "table" and v.tomlfuncs then Toml = v end end 
    params = Toml.config_update(_ENV["!guid"], params)
end)

local players_pickup = {}
local self_pickup = false

function update_pickup_net(m_id, value)
    players_pickup[m_id] = value
end

function init()

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
        if ImGui.IsKeyDown(params['pickup_key']) then
            if self_pickup == false then
                self_pickup = true
                local player = Player.get_client()
                players_pickup[player.m_id] = true
                Net.send("Pickup.update_pickup", Net.TARGET.all, nil, player.m_id, true)
            end
        else
            if self_pickup == true then
                self_pickup = false
                local player = Player.get_client()
                players_pickup[player.m_id] = false
                Net.send("Pickup.update_pickup", Net.TARGET.all, nil, player.m_id, false)
            end
        end
    end)
    Net.register("Pickup.update_pickup", update_pickup_net)
end

Initialize(init)
