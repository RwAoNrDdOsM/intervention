local mod = get_mod("intervention")
--local HideBuff = get_mod("HideBuffs")
local position_lookup = POSITION_LOOKUP
local player_units = PLAYER_UNITS
local player_positions = PLAYER_POSITIONS
local player_and_bot_units = PLAYER_AND_BOT_UNITS
local player_and_bot_positions = PLAYER_AND_BOT_POSITIONS
local ingame_hud_definitions = local_require("scripts/ui/views/ingame_hud_definitions")
--[[local mod_debugmenu = get_mod("DebugMenu")
local list = ingame_hud_definitions
mod_debugmenu.app.list:setList(list)]]
local settings = {
	loneliness_text_team = {
    x = 74,
		y = 45,
		z = 777, --52
  },
	loneliness_text_player = {
    x = 0,
    y = 125,
    z = 999, --52
	}
}

mod:dofile("scripts/mods/intervention/intervention_indicator_ui")

mod:hook_safe(IngameUI, "init", function (self, ingame_ui_context)
  InterventionIndicatorUI = InterventionIndicatorUI:new(ingame_ui_context)
end)

mod:hook_safe(IngameUI, "destroy", function (self)
  InterventionIndicatorUI:destroy()
end)

UISettings.intervention_indicator = {
  wait_time = 1,
	fade_time = 1,
}

mod:hook_safe(IngameUI, "update", function (self, dt, t, disable_ingame_ui, end_of_level_ui)
	local _disable_ingame_ui =  self._disable_ingame_ui 
	local end_screen_active = self:end_screen_active()
  if not _disable_ingame_ui and not end_screen_active then
    if InterventionIndicatorUI then
      InterventionIndicatorUI:update(dt)
    else 
      mod:echo("Intervention Indicator UI not initialized. Please restart level")
    end
	end
end)

mod:hook_safe(HordeSpawner, "execute_custom_horde", function (self, spawn_list, only_ahead)
  if only_ahead then
    InterventionIndicatorUI:set_current_intervention(mod:localize("speed_run_intervention_horde"))
  end
end)

mod:hook_safe(HordeSpawner, "execute_ambush_horde", function (self, extra_data, fallback, override_epicenter_pos)
  if override_epicenter_pos then
    InterventionIndicatorUI:set_current_intervention(mod:localize("rush_intervention_horde"))
  end
end)

mod:hook_safe(ConflictDirector, "spawn_queued_unit", function (self, breed, boxed_spawn_pos, boxed_spawn_rot, spawn_category, spawn_animation, spawn_type, optional_data, group_data, unit_data)
  if spawn_category == "rush_intervention" then
    InterventionIndicatorUI:set_current_intervention(mod:localize("rush_intervention"))
  elseif spawn_category == "speed_run_intervention" then
    InterventionIndicatorUI:set_current_intervention(mod:localize("speed_run_intervention"))
  elseif spawn_category == "outside_navmesh_intervention" then
    InterventionIndicatorUI:set_current_intervention(mod:localize("outside_navmesh_intervention"))
  end
end)

mod:command("test", mod:localize("test_command_description"), function(x) 
  if x then
    InterventionIndicatorUI:set_current_intervention(x, nil)
  else
    InterventionIndicatorUI:set_current_intervention("Test", nil)
  end
end)

mod:hook_safe(UnitFramesHandler, "update", function (self, dt, t)
  local unit_frames = self._unit_frames
  for i = 1, #self._unit_frames, 1 do
    local unit_frame_ui = self._unit_frames[i].widget
    unit_frame_ui:store_unit_frames(self._unit_frames)
  end
end)

mod:hook_safe(UnitFrameUI, "init", function (self, ingame_ui_context, definitions, data, frame_index)
	self._unit_frames_stored = nil
end)

UnitFrameUI.store_unit_frames = function(self, unit_frames)
  if self._unit_frames_stored == unit_frames then
  else
    self._unit_frames_stored = unit_frames
  end
end

-- Store frame_index in a new variable.
mod:hook_safe(UnitFrameUI, "_create_ui_elements", function(self, frame_index)
  self._mod_frame_index = frame_index -- nil for player, 2 3 4 for other players
end)

mod:hook_safe(UnitFrameUI, "update", function(self, dt, t)
	mod:pcall(function()
    if not self._mod_frame_index then -- player UI
      if not self._player_custom_widget then
				self._player_custom_widget = UIWidget.init(mod.player_ui_custom_def)
      end
      
      local player_widget_style = self._player_custom_widget.style
      local loneliness_text_x = settings.loneliness_text_player.x --+ mod:get(mod.SETTING_NAMES.TEAM_UI_NUMERIC_UI_loneliness_OFFSET_X)
			player_widget_style.loneliness_text.offset[1] = loneliness_text_x
			player_widget_style.loneliness_text_shadow.offset[1] = loneliness_text_x + 2

			local loneliness_text_y = settings.loneliness_text_player.y --+ mod:get(mod.SETTING_NAMES.TEAM_UI_NUMERIC_UI_loneliness_OFFSET_Y)
			player_widget_style.loneliness_text.offset[2] = loneliness_text_y
      player_widget_style.loneliness_text_shadow.offset[2] = loneliness_text_y - 2

      local player_widget_content = self._player_custom_widget.content
      local pos = PLAYER_AND_BOT_POSITIONS
      local loneliest_index, loneliness = mod:update_loneliness_value(pos)
      local loneliness_value_index = 0
      if self._unit_frames_stored ~= nil then
        local unit_frame = self._unit_frames_stored[1]
        local player_data = unit_frame.player_data
        local player_unit = player_data.player_unit
        for i = 1, #PLAYER_AND_BOT_UNITS, 1 do
          if player_unit == PLAYER_AND_BOT_UNITS[i] then
            loneliness_value_index = i
          end
        end
      end
      
      if loneliness_value_index == 0 then
        player_widget_content.loneliness_string = ""
      elseif loneliness == "false" then
        player_widget_content.loneliness_string = ""
      else
        player_widget_content.loneliness_string = string.format("%.1f", loneliness[loneliness_value_index])
      end
    elseif self._mod_frame_index then -- changes to the non-player portraits UI
      if not self._teammate_custom_widget then
				self._teammate_custom_widget = UIWidget.init(mod.teammate_ui_custom_def)
			end
      local teammate_widget_style = self._teammate_custom_widget.style
      local loneliness_text_x = settings.loneliness_text_team.x --+ mod:get(mod.SETTING_NAMES.TEAM_UI_NUMERIC_UI_loneliness_OFFSET_X)
			teammate_widget_style.loneliness_text.offset[1] = loneliness_text_x
			teammate_widget_style.loneliness_text_shadow.offset[1] = loneliness_text_x + 2

			local loneliness_text_y = settings.loneliness_text_team.y --+ mod:get(mod.SETTING_NAMES.TEAM_UI_NUMERIC_UI_loneliness_OFFSET_Y)
			teammate_widget_style.loneliness_text.offset[2] = loneliness_text_y
      teammate_widget_style.loneliness_text_shadow.offset[2] = loneliness_text_y - 2

      local teammate_widget_content = self._teammate_custom_widget.content
      local pos = PLAYER_AND_BOT_POSITIONS
      local loneliest_index, loneliness = mod:update_loneliness_value(pos)
      local loneliness_value_index = 0
      if self._unit_frames_stored ~= nil then
        local unit_frame = self._unit_frames_stored[self._mod_frame_index + 1]
        local player_data = unit_frame.player_data
        local player_unit = player_data.player_unit
        for i = 1, #PLAYER_AND_BOT_UNITS, 1 do
          if player_unit == PLAYER_AND_BOT_UNITS[i] then
            loneliness_value_index = i
          end
        end   
      end

      if loneliness == "false" then
        teammate_widget_content.loneliness_string = ""
      elseif loneliness_value_index == 0 then
        teammate_widget_content.loneliness_string = ""
      else
        teammate_widget_content.loneliness_string = string.format("%.1f", loneliness[loneliness_value_index])
      end
    end
  end)
end)

mod:hook(UnitFrameUI, "draw", function(func, self, dt)
	mod:pcall(function()
		if not self._is_visible then
			return -- just from pcall
		end

		if not self._dirty then
			return -- just from pcall
		end

		if not self._mod_frame_index then -- PLAYER UI
			--self.ui_scenegraph.pivot.position[1] = mod:get(mod.SETTING_NAMES.PLAYER_UI_OFFSET_X)
      --self.ui_scenegraph.pivot.position[2] = mod:get(mod.SETTING_NAMES.PLAYER_UI_OFFSET_Y)
      if not self._player_custom_widget then
				self._player_custom_widget = UIWidget.init(mod.player_ui_custom_def)
			end
    elseif self._mod_frame_index then -- TEAMMATE UI
      if not self._teammate_custom_widget then
				self._teammate_custom_widget = UIWidget.init(mod.teammate_ui_custom_def)
			end
    end
  end)

  if not self._mod_frame_index and self._is_visible then -- PLAYER UI
    local player_widget = self._player_custom_widget
    if player_widget then
      local pos = PLAYER_AND_BOT_POSITIONS
      local loneliest_index, loneliness = mod:update_loneliness_value(pos)
      local loneliness_value_index = 0
      if self._unit_frames_stored ~= nil then
        local unit_frame = self._unit_frames_stored[1]
        local player_data = unit_frame.player_data
        local player_unit = player_data.player_unit
        for i = 1, #PLAYER_AND_BOT_UNITS, 1 do
          if player_unit == PLAYER_AND_BOT_UNITS[i] then
            loneliness_value_index = i
          end
        end
      end
      if loneliness_value_index == 0 then
        player_widget.content.loneliness_string = ""
      elseif loneliness == "false" then
        player_widget.content.loneliness_string = ""
      else
        player_widget.content.loneliness_string = string.format("%.1f", loneliness[loneliness_value_index])
      end
      local ui_renderer = self.ui_renderer
      local ui_scenegraph = self.ui_scenegraph
      local input_service = self.input_manager:get_service("ingame_menu")
      local render_settings = self.render_settings
      UIRenderer.begin_pass(ui_renderer, ui_scenegraph, input_service, dt, nil, render_settings)
      UIRenderer.draw_widget(ui_renderer, self._player_custom_widget)
      UIRenderer.end_pass(ui_renderer)
    end
  elseif self._mod_frame_index and self._is_visible then -- changes to the non-player portraits UI
    local teammate_widget = self._teammate_custom_widget
    if teammate_widget then
      local pos = PLAYER_AND_BOT_POSITIONS
      local loneliest_index, loneliness = mod:update_loneliness_value(pos)
      local loneliness_value_index = 0
      if self._unit_frames_stored ~= nil then
        local unit_frame = self._unit_frames_stored[self._mod_frame_index + 1]
        local player_data = unit_frame.player_data
        local player_unit = player_data.player_unit
        for i = 1, #PLAYER_AND_BOT_UNITS, 1 do
          if player_unit == PLAYER_AND_BOT_UNITS[i] then
            loneliness_value_index = i
          end
        end  
      end  
      if loneliness == "false" then
        teammate_widget.content.loneliness_string = ""
      elseif loneliness_value_index == 0 then
        teammate_widget.content.loneliness_string = ""
      else
        teammate_widget.content.loneliness_string = string.format("%.1f", loneliness[loneliness_value_index])
      end
      local ui_renderer = self.ui_renderer
      local ui_scenegraph = self.ui_scenegraph
      local input_service = self.input_manager:get_service("ingame_menu")
      local render_settings = self.render_settings
      UIRenderer.begin_pass(ui_renderer, ui_scenegraph, input_service, dt, nil, render_settings)
      UIRenderer.draw_widget(ui_renderer, self._teammate_custom_widget)
      UIRenderer.end_pass(ui_renderer)
    end
  end
  
  func(self, dt)
end)

local loneliness = {}

mod.update_loneliness_value = function (self, positions, units)
	local distance_squared = Vector3.distance_squared
  local num_positions = #positions

  if num_positions == 1 then
    
		return 1, "false"
	elseif num_positions == 0 then
		return 0, "false"
	end

	local a = positions[1]
	local b = positions[2]
	local c = positions[3]
	local d = positions[4]
	local ab = 0
	local ac = 0
	local ad = 0
	local bc = 0
	local bd = 0
	local cd = 0

	if d then
		ad = distance_squared(a, d)
		bd = distance_squared(b, d)
		cd = distance_squared(c, d)
		loneliness[4] = ad + bd + cd
	end

	if c then
		ac = distance_squared(a, c)
		bc = distance_squared(b, c)
		loneliness[3] = ac + bc + cd
	end

	if b then
		ab = distance_squared(a, b)
		loneliness[2] = ab + bc + bd
	end

	loneliness[1] = ab + ac + ad
	local loneliest_value = 0
	local loneliest_index = 1

	for i = 1, num_positions, 1 do
		if loneliest_value < loneliness[i] then
			loneliest_value = loneliness[i]
			loneliest_index = i
		end
	end
  
  --loneliest_value = math.sqrt(loneliest_value) / num_positions
  
  for i = 1, num_positions, 1 do
    loneliness[i] = math.sqrt(loneliness[i]) / num_positions
  end



	return loneliest_index, loneliness
end

mod.teammate_ui_custom_def = {
	scenegraph_id = "pivot",
	element = {
    passes = {
      {
        style_id = "loneliness_text",
        pass_type = "text",
        text_id = "loneliness_string",
        retained_mode = false,
        content_check_function = function ()
          return true
        end
      },
      {
        style_id = "loneliness_text_shadow",
        pass_type = "text",
        text_id = "loneliness_string",
        retained_mode = false,
        content_check_function = function ()
          return true
        end
      },
    },
	},
  content = {
    loneliness_string = "",
  },
  style = {
    loneliness_text = {
      vertical_alignment = "center",
      font_type = "hell_shark",
      font_size = 22,
      horizontal_alignment = "center",
      text_color = Colors.get_table("white"),
      offset = {
        settings.loneliness_text_team.x,
			  settings.loneliness_text_team.y,
			  settings.loneliness_text_team.z
      }
    },
    loneliness_text_shadow = {
      vertical_alignment = "center",
      font_type = "hell_shark",
      font_size = 22,
      horizontal_alignment = "center",
      text_color = Colors.get_table("black"),
      offset = {
        settings.loneliness_text_team.x + 2,
			  settings.loneliness_text_team.y - 2,
			  settings.loneliness_text_team.z - 1
      }
    },
  },
  offset = {
		12+0,
		-60-2+0,
		-10
	},
}

mod.player_ui_custom_def = {
	scenegraph_id = "pivot",
	element = {
    passes = {
      {
        style_id = "loneliness_text",
        pass_type = "text",
        text_id = "loneliness_string",
        retained_mode = false,
        content_check_function = function ()
          return true
        end
      },
      {
        style_id = "loneliness_text_shadow",
        pass_type = "text",
        text_id = "loneliness_string",
        retained_mode = false,
        content_check_function = function ()
          return true
        end
      },
    },
	},
  content = {
    loneliness_string = "",
  },
  style = {
    loneliness_text = {
      vertical_alignment = "center",
      font_type = "hell_shark",
      font_size = 22,
      horizontal_alignment = "center",
      text_color = Colors.get_table("white"),
      offset = {
        settings.loneliness_text_player.x,
			  settings.loneliness_text_player.y,
			  settings.loneliness_text_player.z
      }
    },
    loneliness_text_shadow = {
      vertical_alignment = "center",
      font_type = "hell_shark",
      font_size = 22,
      horizontal_alignment = "center",
      text_color = Colors.get_table("black"),
      offset = {
        settings.loneliness_text_player.x + 2,
			  settings.loneliness_text_player.y - 2,
			  settings.loneliness_text_player.z - 1
      }
    },
  },
  offset = {
			0,
			0,
			0
		}
}