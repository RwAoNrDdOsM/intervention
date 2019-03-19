local mod = get_mod("intervention")
--local HideBuff = get_mod("HideBuffs")
local position_lookup = POSITION_LOOKUP
local player_units = PLAYER_UNITS
local player_positions = PLAYER_POSITIONS
local player_and_bot_units = PLAYER_AND_BOT_UNITS
local player_and_bot_positions = PLAYER_AND_BOT_POSITIONS
--[[local mod_debugmenu = get_mod("DebugMenu")
mod_debugmenu.app.list:setList(list)]]
local settings = {
	loneliness_text_team = {
    x = 74,
		y = 45,
		z = 777, --52
  },
	loneliness_text_player = {
    x = -2, 
    y = 125,
    z = 999, --52
  },
  timer_text = {
    x = 350, -- 350
    y = 30,
    z = 999 --52
  },
}

mod:hook_origin(UIRenderer, "begin_pass", function (self, ui_scenegraph, input_service, dt, parent_scenegraph_id, render_settings)
	if self.ui_scenegraph then
		local old_scenegraph = self.ui_scenegraph

		pdArray.push_back(self.ui_scenegraph_queue, old_scenegraph)

		self.ui_scenegraph = ui_scenegraph

		assert(parent_scenegraph_id, "Must provide parent scenegraph id when building multiple depth passes.")
		UISceneGraph.update_scenegraph(ui_scenegraph, old_scenegraph, parent_scenegraph_id)
	else
		self.ui_scenegraph = ui_scenegraph

		UISceneGraph.update_scenegraph(ui_scenegraph)
	end

	self.ui_scenegraph = ui_scenegraph
	self.input_service = input_service
	self.dt = dt
	self.render_settings = render_settings

	if script_data.ui_debug_scenegraph then
		if DebugKeyHandler.key_pressed("left shift", "Debug Child Scenegraphs", "UI") and parent_scenegraph_id then
			UISceneGraph.debug_render_scenegraph(self, ui_scenegraph)
		elseif not parent_scenegraph_id then
			UISceneGraph.debug_render_scenegraph(self, ui_scenegraph)
		end
	end

	if script_data.ui_debug_pixeldistance and not parent_scenegraph_id then
		local debug_pixeldistance_value = input_service and input_service:get("debug_pixeldistance")

		if debug_pixeldistance_value then
			local cursor = input_service:get("cursor")

			if not self.debug_startpoint then
				self.debug_startpoint = Vector3Aux.box({}, cursor)
				self.debug_startpoint[3] = 999
			end

			local debug_startpoint = self.debug_startpoint
			local cursor_distance = Vector3.distance(Vector3Aux.unbox(debug_startpoint), cursor)

			if cursor_distance > 0 then
				if math.abs(cursor.y - debug_startpoint[2]) < math.abs(cursor.x - debug_startpoint[1]) then
					local current_endpos = Vector3(cursor.x, debug_startpoint[2], 999)

					Gui.rect(self.gui, Vector3Aux.unbox(debug_startpoint), Vector2(cursor.x - debug_startpoint[1], 20), Color(128, 255, 255, 255))

					local text = string.format("%d pixels.", cursor.x - debug_startpoint[1])

					Gui.text(self.gui, text, "materials/fonts/gw_arial_16", 14, "gw_arial_16", Vector3Aux.unbox(debug_startpoint), Color(255, 255, 255, 255))
				else
					local current_endpos = Vector3(debug_startpoint[1], cursor.y, 999)

					Gui.rect(self.gui, Vector3Aux.unbox(debug_startpoint), Vector2(20, cursor.y - debug_startpoint[2]), Color(128, 255, 255, 255))

					local text = string.format("%d pixels.", cursor.y - debug_startpoint[2])

					Gui.text(self.gui, text, "materials/fonts/gw_arial_16", 14, "gw_arial_16", Vector3Aux.unbox(debug_startpoint), Color(255, 255, 255, 255))
				end
			end
		elseif self.debug_startpoint and not input_service:is_blocked() then
			self.debug_startpoint_direction = nil
			self.debug_startpoint = nil
		end
	end
end)

-- InterventionIndicatorUI
mod:dofile("scripts/mods/intervention/ui/intervention_indicator_ui")
mod:dofile("scripts/mods/intervention/ui/intervention_breed_ui")

mod:hook_safe(IngameHud, "init", function (self, parent, ingame_ui_context)
  InterventionIndicatorUI = InterventionIndicatorUI:new(parent, ingame_ui_context)
  InterventionBreedUI = InterventionBreedUI:new(parent, ingame_ui_context)
end)

mod:hook_safe(IngameHud, "destroy", function (self)
  InterventionIndicatorUI:destroy()
  InterventionBreedUI:destroy()
end)

UISettings.intervention_indicator = {
  wait_time = 1,
	fade_time = 1,
}

UISettings.intervention_breed = {
  fade_duration = 0.5,
  show_duration = 4,
  increment_duration = 0.33
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
    if InterventionBreedUI then
      InterventionBreedUI:update(dt, t)
      
    else 
      mod:echo("Intervention Breed UI not initialized. Please restart level")
    end
	end
end)

  local specials_settings = CurrentSpecialsSettings
  local breeds = specials_settings.rush_intervention.breeds
  if #breed == 0 then
    return mod:echo("No Breeds")
  end

  for i = 1, #breeds, 1 do
    Managers.state.event:trigger("add_breed_ui_info", breeds[i], "rush")
    mode:echo(torstring(breeds[i]))
  end

mod:hook_safe(HordeSpawner, "execute_custom_horde", function (self, spawn_list, only_ahead)
  if only_ahead then
    InterventionIndicatorUI:set_current_intervention("speedrun")
  end
end)

-- Rush Intervention Horde, uneeded as you'll get special + 25% of horde unlike speedrunning intervention
--[[mod:hook_safe(HordeSpawner, "execute_ambush_horde", function (self, extra_data, fallback, override_epicenter_pos)
  if override_epicenter_pos then
    InterventionIndicatorUI:set_current_intervention(mod:localize("rush_intervention"))
  end
end)]]

mod:hook_safe(ConflictDirector, "spawn_queued_unit", function (self, breed, boxed_spawn_pos, boxed_spawn_rot, spawn_category, spawn_animation, spawn_type, optional_data, group_data, unit_data)
  local specials_settings = CurrentSpecialsSettings
  if spawn_category == "rush_intervention" then
    InterventionIndicatorUI:set_current_intervention("rush")
    local breeds = specials_settings.rush_intervention.breeds
    for i = 1, #breeds, 1 do
      Managers.state.event:trigger("add_breed_ui_info", breeds[i], "rush")
    end
  elseif spawn_category == "speed_run_intervention" then
    InterventionIndicatorUI:set_current_intervention("speedrun")
    local breeds = specials_settings.speed_running_intervention.breeds
    for i = 1, #breeds, 1 do
      Managers.state.event:trigger("add_breed_ui_info", breeds[i], "rush")
    end
  elseif spawn_category == "outside_navmesh_intervention" then
    InterventionIndicatorUI:set_current_intervention("navmesh")
    local breeds = specials_settings.outside_navmesh_intervention.breeds
    for i = 1, #breeds, 1 do
      Managers.state.event:trigger("add_breed_ui_info", breeds[i], "rush")
    end
  end
end)

mod:hook_safe(ConflictDirector, "init", function(self, world, level_key, network_event_delegate)
  self.saved_next_intervention_time = {0,0,0}
end)

ConflictDirector._next_intervention_time = function(self)
  local t = self._time
  self.current_next_intervention_time = {
    0,
    0,
    0
  }
  local conflict_settings = CurrentConflictSettings

  if conflict_settings.disabled then
		return self.current_next_intervention_time
	end
  
  local script_data = script_data

  if not script_data.ai_pacing_disabled and not conflict_settings.pacing.disabled and self.saved_next_intervention_time[1] <= 0 then
		if self._next_rushing_intervention_time > t + 1 and not script_data.ai_rush_intervention_disabled then
			self.current_next_intervention_time[1] = self._next_rushing_intervention_time - t
    end

		local settings = CurrentSpecialsSettings.speed_running_intervention or SpecialsSettings.default.speed_running_intervention

		if self._next_speed_running_intervention_time >= (t + 2.51) and not script_data.ai_speed_running_intervention_disabled and not settings.disabled and self.saved_next_intervention_time[2] <= 0 then 
			self.current_next_intervention_time[2] = self._next_speed_running_intervention_time - t
    end
	end

  --Debug for if Outside Navmesh Intervention is ever enabled
  --[[conflict_settings.specials.outside_navmesh_intervention.disabled = false
  if not self.in_safe_zone then
    if not conflict_settings.specials.disabled then
			if self._next_outside_navmesh_intervention_time > t and not conflict_settings.specials.outside_navmesh_intervention.disabled and not script_data.ai_outside_navmesh_intervention_disabled then
        self.current_next_intervention_time[3] = self._next_outside_navmesh_intervention_time - 1.15
      end
    end
  end]]

  if self.current_next_intervention_time == self.saved_next_intervention_time then
    return self.saved_next_intervention_time
  else
    self.saved_next_intervention_time = self.current_next_intervention_time
    return self.saved_next_intervention_time
  end
end

-- Frame stuff (Lonliness Value / Timers)
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
  self._mod_frame_index = frame_index -- nil for player, 1 2 3 for other players
end)

mod:hook_safe(UnitFrameUI, "update", function(self, dt, t)
	mod:pcall(function()
    if not self._mod_frame_index then -- player UI
      if not self._player_custom_widget then
				self._player_custom_widget = UIWidget.init(mod.player_ui_custom_def)
      end
      
      -- Position
      
      local player_widget_style = self._player_custom_widget.style
      local loneliness_text_x = settings.loneliness_text_player.x 
      local loneliness_text_y = settings.loneliness_text_player.y
      local timer_rush_text_x = settings.timer_text.x 
      local timer_rush_text_y = settings.timer_text.y
      local timer_speedrun_text_x = settings.timer_text.x 
      local timer_speedrun_text_y = settings.timer_text.y + 24

      if Managers.state.conflict then
        local conflict_director = Managers.state.conflict
        local timer = conflict_director:_next_intervention_time(t)
        if timer[1] == 0 then
          timer_speedrun_text_y = settings.timer_text.y
        end
      end
      --[[if HideBuff then
        loneliness_text_x = loneliness_text_x + HideBuff:get(mod.SETTING_NAMES.PLAYER_UI_OFFSET_X)
        loneliness_text_y = loneliness_text_y + HideBuff:get(mod.SETTING_NAMES.PLAYER_UI_OFFSET_Y)
        timer_rush_text_x = timer_rush_text_x + HideBuff:get(mod.SETTING_NAMES.PLAYER_UI_OFFSET_X)
        timer_rush_text_y = timer_rush_text_y + HideBuff:get(mod.SETTING_NAMES.PLAYER_UI_OFFSET_Y)
        timer_speedrun_text_x = timer_speedrun_text_x + HideBuff:get(mod.SETTING_NAMES.PLAYER_UI_OFFSET_X)
        timer_speedrun_text_y = timer_speedrun_text_y + HideBuff:get(mod.SETTING_NAMES.PLAYER_UI_OFFSET_Y)
      end]]

			player_widget_style.loneliness_text.offset[1] = loneliness_text_x
      player_widget_style.loneliness_text_shadow.offset[1] = loneliness_text_x + 2
			player_widget_style.loneliness_text.offset[2] = loneliness_text_y
      player_widget_style.loneliness_text_shadow.offset[2] = loneliness_text_y - 2      
      player_widget_style.timer_rush_text.offset[1] = timer_rush_text_x
      player_widget_style.timer_rush_text_shadow.offset[1] = timer_rush_text_x + 2
      player_widget_style.timer_rush_text.offset[2] = timer_rush_text_y
      player_widget_style.timer_rush_text_shadow.offset[2] = timer_rush_text_y - 2
      player_widget_style.timer_speedrun_text.offset[1] = timer_speedrun_text_x
      player_widget_style.timer_speedrun_text_shadow.offset[1] = timer_speedrun_text_x + 2
      player_widget_style.timer_speedrun_text.offset[2] = timer_speedrun_text_y
      player_widget_style.timer_speedrun_text_shadow.offset[2] = timer_speedrun_text_y + 2
      
       
      if HideBuff then
        timer_speedrun_text_y = timer_speedrun_text_y + HideBuff:get(mod.SETTING_NAMES.PLAYER_UI_OFFSET_Y)
      end
      player_widget_style.timer_speedrun_text.offset[2] = timer_speedrun_text_y
      player_widget_style.timer_speedrun_text.offset[2] = timer_speedrun_text_y - 2
      
      local player_widget_content = self._player_custom_widget.content
      
      -- Loneliness Value
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
        if loneliness[loneliness_value_index] >= 30 then
          player_widget_style.loneliness_text.text_color = Colors.get_table("red")
        else
          player_widget_style.loneliness_text.text_color = Colors.get_table("white")
        end
      end

      -- Timers
      
      if Managers.state.conflict then
        local conflict_director = Managers.state.conflict
        local timer = conflict_director:_next_intervention_time(t)
        local timer_rush_min = math.floor(timer[1] / 60)
        local timer_rush_sec = timer[1] - (timer_rush_min * 60)
        player_widget_content.timer_rush_string = string.format("%01d:%02d", timer_rush_min, timer_rush_sec)
        local timer_speedrun_min = math.floor(timer[2] / 60)
        local timer_speedrun_sec = timer[2] - (timer_speedrun_min * 60)
        player_widget_content.timer_speedrun_string = string.format("%01d:%02d", timer_speedrun_min, timer_speedrun_sec)
        --local timer_navmesh_min = math.floor(timer[3] / 60)
        --local timer_navmesh_sec = timer[3] - (timer_navmesh_min * 60)
        --player_widget_content.timer_navmesh_string = string.format("%01d:%02d", timer_navmesh_min, timer_navmesh_sec)
      end
    elseif self._mod_frame_index then -- changes to the non-player portraits UI
      if not self._teammate_custom_widget then
				self._teammate_custom_widget = UIWidget.init(mod.teammate_ui_custom_def)
			end
      local teammate_widget_style = self._teammate_custom_widget.style
      local loneliness_text_x = settings.loneliness_text_team.x 
			teammate_widget_style.loneliness_text.offset[1] = loneliness_text_x
			teammate_widget_style.loneliness_text_shadow.offset[1] = loneliness_text_x + 2

			local loneliness_text_y = settings.loneliness_text_team.y
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
        if loneliness[loneliness_value_index] >= 30 then
          teammate_widget_style.loneliness_text.text_color = Colors.get_table("red")
        else
          teammate_widget_style.loneliness_text.text_color = Colors.get_table("white")
        end
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
      --player_widget.content.loneliness_string = ""
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
      --teammate_widget.content.loneliness_string = ""
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
      {
        style_id = "timer_rush_text",
        pass_type = "text",
        text_id = "timer_rush_string",
        retained_mode = false,
        content_check_function = function (content)
          if content.timer_rush_string == "0:00" then
            return  
          end

          return true
        end
      },
      {
        style_id = "timer_rush_text_shadow",
        pass_type = "text",
        text_id = "timer_rush_string",
        retained_mode = false,
        content_check_function = function (content)
          if content.timer_rush_string == "0:00" then
            return
          end

          return true
        end
      },
      {
        style_id = "timer_speedrun_text",
        pass_type = "text",
        text_id = "timer_speedrun_string",
        retained_mode = false,
        content_check_function = function (content)
          if content.timer_speedrun_string == "0:00" then
            return
          end

          return true
        end
      },
      {
        style_id = "timer_speedrun_text_shadow",
        pass_type = "text",
        text_id = "timer_speedrun_string",
        retained_mode = false,
        content_check_function = function (content)
          if content.timer_speedrun_string == "0:00" then
            return
          end

          return true
        end
      },
      {
        style_id = "timer_navmesh_text",
        pass_type = "text",
        text_id = "timer_navmesh_string",
        retained_mode = false,
        content_check_function = function (content)
          if content.timer_navmesh_string == "0:00" then
            return
          end

          return true
        end
      },
      {
        style_id = "timer_navmesh_text_shadow",
        pass_type = "text",
        text_id = "timer_navmesh_string",
        retained_mode = false,
        content_check_function = function (content)
          if content.timer_navmesh_string == "0:00" then
            return
          end

          return true
        end
      },
    },
	},
  content = {
    loneliness_string = "",
    timer_rush_string = "0:00",
    timer_speedrun_string = "0:00",
    timer_navmesh_string = "0:00",
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
    timer_rush_text = {
      vertical_alignment = "center",
      font_type = "hell_shark",
      font_size = 22,
      horizontal_alignment = "center",
      text_color = Colors.get_table("red"),
      size = {
				22,
				22
			},
      offset = {
        settings.timer_text.x,
			  settings.timer_text.y,
			  settings.timer_text.z
      }
    },
    timer_rush_text_shadow = {
      vertical_alignment = "center",
      font_type = "hell_shark",
      font_size = 22,
      horizontal_alignment = "center",
      text_color = Colors.get_table("black"),
      size = {
				22,
				22
			},
      offset = {
        settings.timer_text.x + 2,
			  settings.timer_text.y - 2,
			  settings.timer_text.z - 1
      }
    },
    timer_speedrun_text = {
      vertical_alignment = "center",
      font_type = "hell_shark",
      font_size = 22,
      horizontal_alignment = "center",
      text_color = Colors.get_table("cheeseburger"),
      size = {
				22,
				22
			},
      offset = {
        settings.timer_text.x,
			  settings.timer_text.y + 24,
			  settings.timer_text.z
      }
    },
    timer_speedrun_text_shadow = {
      vertical_alignment = "center",
      font_type = "hell_shark",
      font_size = 22,
      horizontal_alignment = "center",
      text_color = Colors.get_table("black"),
      size = {
				22,
				22
			},
      offset = {
        settings.timer_text.x + 2,
			  settings.timer_text.y - 2 + 24,
			  settings.timer_text.z - 1
      }
    },
    timer_navmesh_text = {
      vertical_alignment = "center",
      font_type = "hell_shark",
      font_size = 22,
      horizontal_alignment = "center",
      text_color = Colors.get_table("white"),
      size = {
				22,
				22
			},
      offset = {
        settings.timer_text.x,
			  settings.timer_text.y + 48,
			  settings.timer_text.z
      }
    },
    timer_navmesh_text_shadow = {
      vertical_alignment = "center",
      font_type = "hell_shark",
      font_size = 22,
      horizontal_alignment = "center",
      text_color = Colors.get_table("black"),
      size = {
				22,
				22
			},
      offset = {
        settings.timer_text.x + 2,
			  settings.timer_text.y - 2 + 48,
			  settings.timer_text.z - 1
      }
    },
  },
  offset = {
			0,
			0,
			0
		}
}