local mod = get_mod("intervention")
local HideBuff = get_mod("HideBuffs")
local NumericUI = get_mod("NumericUI")
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

--RPCS
mod:network_register("intervention_triggered", function(sender, intervention_type)
  if intervention_type == "rush_intervention" then
    InterventionIndicatorUI:set_current_intervention("rush")
  elseif intervention_type == "speed_run_intervention" then
    InterventionIndicatorUI:set_current_intervention("speedrun")
  elseif intervention_type == "outside_navmesh_intervention" then
    InterventionIndicatorUI:set_current_intervention("navmesh")
  end
end)

mod.intervention_time = {
  0,
  0,
  0,
}

mod:network_register("intervention_timer", function(sender, rush_timer, speedrun_timer, navmesh_timer)
  if rush_timer ~= 0 then
    mod.intervention_time[1] = rush_timer
  end
  if speedrun_timer ~= 0 then
    mod.intervention_time[2] = speedrun_timer
  end
  if navmesh_timer ~= 0 then
    mod.intervention_time[3] = navmesh_timer
  end
end)


-- InterventionIndicatorUI
mod:dofile("scripts/mods/intervention/ui/intervention_indicator_ui")
mod:dofile("scripts/mods/intervention/ui/intervention_breed_ui")

mod:hook_safe(IngameHud, "init", function (self, parent, ingame_ui_context)
  InterventionIndicatorUI = InterventionIndicatorUI:new(parent, ingame_ui_context)
  --InterventionBreedUI = InterventionBreedUI:new(parent, ingame_ui_context)
end)

mod:hook_safe(IngameHud, "destroy", function (self)
  InterventionIndicatorUI:destroy()
 -- InterventionBreedUI:destroy()
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
    --[[if InterventionBreedUI then
      InterventionBreedUI:update(dt, t)
      
    else 
      mod:echo("Intervention Breed UI not initialized. Please restart level")
    end]]
	end
end)

mod:hook_safe(HordeSpawner, "execute_custom_horde", function (self, spawn_list, only_ahead)
  if only_ahead then
    InterventionIndicatorUI:set_current_intervention("speedrun")
    mod:network_send("intervention_triggered", "others", "speedrun")
  end
end)

-- Rush Intervention Horde, not needed as you'll get special + 25% of horde unlike speedrunning intervention
--[[mod:hook_safe(HordeSpawner, "execute_ambush_horde", function (self, extra_data, fallback, override_epicenter_pos)
  if override_epicenter_pos then
    InterventionIndicatorUI:set_current_intervention(mod:localize("rush_intervention"))
  end
end)]]

mod:hook_safe(ConflictDirector, "spawn_queued_unit", function (self, breed, boxed_spawn_pos, boxed_spawn_rot, spawn_category, spawn_animation, spawn_type, optional_data, group_data, unit_data)
  if spawn_category == "rush_intervention" then
    InterventionIndicatorUI:set_current_intervention("rush")
    mod:network_send("intervention_triggered", "others", spawn_category)
  elseif spawn_category == "speed_run_intervention" then
    InterventionIndicatorUI:set_current_intervention("speedrun")
    mod:network_send("intervention_triggered", "others", spawn_category)  
  elseif spawn_category == "outside_navmesh_intervention" then
    InterventionIndicatorUI:set_current_intervention("navmesh")
    mod:network_send("intervention_triggered", "others", spawn_category)
  end
end)

mod:hook_safe(ConflictDirector, "init", function(self, world, level_key, network_event_delegate)
  self.saved_next_intervention_time = {0,0,0}
  self.rush_timer = true
  self.speedrunning_timer = true
  self.navmesh_timer = true
end)

ConflictDirector._next_intervention_time = function(self)
  local is_server = Managers.state.network.is_server
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
  
  local rushing = self.rush_timer
  local speedrunning = self.speedrunning_timer
  local outside_navmesh = self.navmesh_timer 

  local script_data = script_data

  if not script_data.ai_pacing_disabled and not conflict_settings.pacing.disabled then
		if self._next_rushing_intervention_time > t + 1 and not script_data.ai_rush_intervention_disabled and rushing then
      self.current_next_intervention_time[1] = self._next_rushing_intervention_time - t
      self.rush_timer = false
    elseif not rushing then -- hopefully this means the timer won't disable before it should, not sure if this was an issue but better to have this here
      self.current_next_intervention_time[1] = self._next_rushing_intervention_time - t
      if self.current_next_intervention_time[1] == 0 then
        self.rush_timer = true
      end
    end

		local settings = CurrentSpecialsSettings.speed_running_intervention or SpecialsSettings.default.speed_running_intervention

		if self._next_speed_running_intervention_time >= (t + 2.51) and not script_data.ai_speed_running_intervention_disabled and not settings.disabled and self.saved_next_intervention_time[2] <= 0 and speedrunning then 
      self.current_next_intervention_time[2] = self._next_speed_running_intervention_time - t
      self.speedrunning_timer = false
    elseif not speedrunning then
      self.current_next_intervention_time[2] = self._next_speed_running_intervention_time - t
      if self.current_next_intervention_time[2] == 0 then
        self.speedrunning_timer = true
      end
    end
	end

  --Debug for if Outside Navmesh Intervention
  --conflict_settings.specials.outside_navmesh_intervention.disabled = false
  if not self.in_safe_zone then
    if not conflict_settings.specials.disabled then
			if self._next_outside_navmesh_intervention_time > t and not conflict_settings.specials.outside_navmesh_intervention.disabled and not script_data.ai_outside_navmesh_intervention_disabled and self.saved_next_intervention_time[3] <= 0 and outside_navmesh then
        self.current_next_intervention_time[3] = self._next_outside_navmesh_intervention_time - 1.15
        self.navmesh_timer = false
      elseif not outside_navmesh then
        self.current_next_intervention_time[2] = self._next_outside_navmesh_intervention_time - 1.15
        if self.current_next_intervention_time[2] == 0 then
          self.navmesh_timer = true
        end
      end
    end
  end

  if self.current_next_intervention_time == self.saved_next_intervention_time then
    if self.saved_next_intervention_time[1] ~= 0 or self.saved_next_intervention_time[2] ~= 0 or self.saved_next_intervention_time[3] ~= 0 and is_server then
      mod:network_send("intervention_timer", "others", self.saved_next_intervention_time[1], self.saved_next_intervention_time[2], self.saved_next_intervention_time[3])
    end
    return self.saved_next_intervention_time
  else
    self.saved_next_intervention_time = self.current_next_intervention_time
    if self.saved_next_intervention_time[1] ~= 0 or self.saved_next_intervention_time[2] ~= 0 or self.saved_next_intervention_time[3] ~= 0 and is_server then
      mod:network_send("intervention_timer", "others", self.saved_next_intervention_time[1], self.saved_next_intervention_time[2], self.saved_next_intervention_time[3])
    end
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
      if not self.rwaon_player_custom_widget then
				self.rwaon_player_custom_widget = UIWidget.init(mod.player_ui_custom_def)
      end
      
      -- Position
      
      local player_widget_style = self.rwaon_player_custom_widget.style
      local loneliness_text_x = settings.loneliness_text_player.x + mod:get("loneliness_x")
      local loneliness_text_y = settings.loneliness_text_player.y + mod:get("loneliness_y")
      local timer_rush_text_x = settings.timer_text.x + mod:get("timer_x") 
      local timer_rush_text_y = settings.timer_text.y + mod:get("timer_y") 
      local timer_speedrun_text_x = settings.timer_text.x + mod:get("timer_x") 
      local timer_speedrun_text_y = settings.timer_text.y + mod:get("timer_spacing") + mod:get("timer_y")  
      local timer_navmesh_text_x = settings.timer_text.x + mod:get("timer_x") 
      local timer_navmesh_text_y = settings.timer_text.y + mod:get("timer_spacing") * 2 + mod:get("timer_y") 

      if Managers.state.conflict and not mod:get("always_show_loneliness") then
        local conflict_director = Managers.state.conflict
        local is_server = Managers.state.network.is_server
        local timer = mod.intervention_time
        if is_server then
          timer = conflict_director:_next_intervention_time(t)
        end
        if timer[1] == 0 then
          timer_speedrun_text_y = settings.timer_text.y + mod:get("timer_y") 
          timer_navmesh_text_y = settings.timer_text.y + mod:get("timer_spacing") + mod:get("timer_y") 
        end
        if timer[2] == 0 then
          timer_navmesh_text_y = settings.timer_text.y + mod:get("timer_spacing") + mod:get("timer_y") 
        end
        if timer[1] == 0 and timer[2] == 0 then
          timer_navmesh_text_y = settings.timer_text.y + mod:get("timer_y") 
        end
      end
      if HideBuff then
        loneliness_text_x = loneliness_text_x + HideBuff:get(mod.SETTING_NAMES.PLAYER_UI_OFFSET_X)
        loneliness_text_y = loneliness_text_y + HideBuff:get(mod.SETTING_NAMES.PLAYER_UI_OFFSET_Y)
        timer_rush_text_x = timer_rush_text_x + HideBuff:get(mod.SETTING_NAMES.PLAYER_UI_OFFSET_X)
        timer_rush_text_y = timer_rush_text_y + HideBuff:get(mod.SETTING_NAMES.PLAYER_UI_OFFSET_Y)
        timer_speedrun_text_x = timer_speedrun_text_x + HideBuff:get(mod.SETTING_NAMES.PLAYER_UI_OFFSET_X)
        timer_speedrun_text_y = timer_speedrun_text_y + HideBuff:get(mod.SETTING_NAMES.PLAYER_UI_OFFSET_Y)
        timer_navmesh_text_x = timer_navmesh_text_x + HideBuff:get(mod.SETTING_NAMES.PLAYER_UI_OFFSET_X)
        timer_navmesh_text_y = timer_navmesh_text_y + HideBuff:get(mod.SETTING_NAMES.PLAYER_UI_OFFSET_Y)
      end

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
      player_widget_style.timer_speedrun_text_shadow.offset[2] = timer_speedrun_text_y - 2

      player_widget_style.timer_navmesh_text.offset[1] = timer_navmesh_text_x
      player_widget_style.timer_navmesh_text_shadow.offset[1] = timer_navmesh_text_x + 2

      player_widget_style.timer_navmesh_text.offset[2] = timer_navmesh_text_y
      player_widget_style.timer_navmesh_text_shadow.offset[2] = timer_navmesh_text_y - 2
      
      if player_widget_style.timer_rush_text.font_size ~= mod:get("timer_font_size") or player_widget_style.timer_rush_text_shadow.font_size ~= mod:get("timer_font_size") or player_widget_style.timer_speedrun_text.font_size ~= mod:get("timer_font_size") or player_widget_style.timer_speedrun_text_shadow.font_size ~= mod:get("timer_font_size") or player_widget_style.timer_navmesh_text.font_size ~= mod:get("timer_font_size") or player_widget_style.timer_navmesh_text_shadow.font_size ~= mod:get("timer_font_size") then
        player_widget_style.timer_rush_text.font_size = mod:get("timer_font_size")
        player_widget_style.timer_rush_text_shadow.font_size = mod:get("timer_font_size")
        player_widget_style.timer_speedrun_text.font_size = mod:get("timer_font_size")
        player_widget_style.timer_speedrun_text_shadow.font_size = mod:get("timer_font_size")
        player_widget_style.timer_navmesh_text.font_size = mod:get("timer_font_size")
        player_widget_style.timer_navmesh_text_shadow.font_size = mod:get("timer_font_size")
      end

      local player_widget_content = self.rwaon_player_custom_widget.content
      
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
        if loneliness[loneliness_value_index] < 30 and not mod:get("always_show_loneliness") then
          player_widget_content.loneliness_string = ""
        elseif mod:get("loneliness") == "player" or mod:get("loneliness") == "both" then
          player_widget_content.loneliness_string = string.format("%.1f", loneliness[loneliness_value_index])
        else
          player_widget_content.loneliness_string = ""
        end

        if loneliness[loneliness_value_index] >= 30 and mod:get("turn_red") then
          player_widget_style.loneliness_text.text_color = Colors.get_table("red")
        else
          player_widget_style.loneliness_text.text_color = Colors.get_table("white")
        end

        if player_widget_style.loneliness_text.font_size ~= mod:get("loneliness_font_size") or player_widget_style.loneliness_text_shadow.font_size ~= mod:get("loneliness_font_size") then
          player_widget_style.loneliness_text.font_size = mod:get("loneliness_font_size")
          player_widget_style.loneliness_text_shadow.font_size = mod:get("loneliness_font_size")
        end
      end

      -- Timers
      
      if Managers.state.conflict and mod:get("timers") then
        local conflict_director = Managers.state.conflict
        local is_server = Managers.state.network.is_server
        local timer = mod.intervention_time
        if is_server then
          timer = conflict_director:_next_intervention_time(t)
        end
        local timer_rush_min = math.floor(timer[1] / 60)
        local timer_rush_sec = timer[1] - (timer_rush_min * 60)
        player_widget_content.timer_rush_string = string.format("%01d:%02d", timer_rush_min, timer_rush_sec)
        local timer_speedrun_min = math.floor(timer[2] / 60)
        local timer_speedrun_sec = timer[2] - (timer_speedrun_min * 60)
        player_widget_content.timer_speedrun_string = string.format("%01d:%02d", timer_speedrun_min, timer_speedrun_sec)
        local timer_navmesh_min = math.floor(timer[3] / 60)
        local timer_navmesh_sec = timer[3] - (timer_navmesh_min * 60)
        player_widget_content.timer_navmesh_string = string.format("%01d:%02d", timer_navmesh_min, timer_navmesh_sec)
      else
        player_widget_content.timer_rush_string = ""
        player_widget_content.timer_speedrun_string = ""
        player_widget_content.timer_navmesh_string = ""
      end
    elseif self._mod_frame_index then -- changes to the non-player portraits UI
      if not self.rwaon_teammate_custom_widget then
				self.rwaon_teammate_custom_widget = UIWidget.init(mod.teammate_ui_custom_def)
			end
      local teammate_widget_style = self.rwaon_teammate_custom_widget.style
      local loneliness_text_x = settings.loneliness_text_team.x 
			teammate_widget_style.loneliness_text.offset[1] = loneliness_text_x + mod:get("loneliness_x_team")
			teammate_widget_style.loneliness_text_shadow.offset[1] = loneliness_text_x + 2 + mod:get("loneliness_x_team")

			local loneliness_text_y = settings.loneliness_text_team.y
			teammate_widget_style.loneliness_text.offset[2] = loneliness_text_y + mod:get("loneliness_y_team")
      teammate_widget_style.loneliness_text_shadow.offset[2] = loneliness_text_y - 2 + mod:get("loneliness_y_team")

      local teammate_widget_content = self.rwaon_teammate_custom_widget.content
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
        if loneliness[loneliness_value_index] < 30 and not mod:get("always_show_loneliness") then
          teammate_widget_content.loneliness_string = ""
        elseif mod:get("loneliness") == "team" or mod:get("loneliness") == "both" then
          teammate_widget_content.loneliness_string = string.format("%.1f", loneliness[loneliness_value_index])
        else
          teammate_widget_content.loneliness_string = ""
        end

        if loneliness[loneliness_value_index] >= 30 and mod:get("turn_red") then
          teammate_widget_style.loneliness_text.text_color = Colors.get_table("red")
        else
          teammate_widget_style.loneliness_text.text_color = Colors.get_table("white")
        end
        
        if teammate_widget_style.loneliness_text.font_size ~= mod:get("loneliness_font_size") or teammate_widget_style.loneliness_text_shadow.font_size ~= mod:get("loneliness_font_size") then
          teammate_widget_style.loneliness_text.font_size = mod:get("loneliness_font_size")
          teammate_widget_style.loneliness_text_shadow.font_size = mod:get("loneliness_font_size")
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
      if not self.rwaon_player_custom_widget then
				self.rwaon_player_custom_widget = UIWidget.init(mod.player_ui_custom_def)
			end
    elseif self._mod_frame_index then -- TEAMMATE UI
      if not self.rwaon_teammate_custom_widget then
				self.rwaon_teammate_custom_widget = UIWidget.init(mod.teammate_ui_custom_def)
			end
    end
  end)

  if not self._mod_frame_index and self._is_visible then -- PLAYER UI
    local player_widget = self.rwaon_player_custom_widget
    if player_widget then
      --player_widget.content.loneliness_string = ""
      local ui_renderer = self.ui_renderer
      local ui_scenegraph = self.ui_scenegraph
      local input_service = self.input_manager:get_service("ingame_menu")
      local render_settings = self.render_settings
      UIRenderer.begin_pass(ui_renderer, ui_scenegraph, input_service, dt, nil, render_settings)
      UIRenderer.draw_widget(ui_renderer, self.rwaon_player_custom_widget)
      UIRenderer.end_pass(ui_renderer)
    end
  elseif self._mod_frame_index and self._is_visible then -- changes to the non-player portraits UI
    local teammate_widget = self.rwaon_teammate_custom_widget
    if teammate_widget then
      --teammate_widget.content.loneliness_string = ""
      local ui_renderer = self.ui_renderer
      local ui_scenegraph = self.ui_scenegraph
      local input_service = self.input_manager:get_service("ingame_menu")
      local render_settings = self.render_settings
      UIRenderer.begin_pass(ui_renderer, ui_scenegraph, input_service, dt, nil, render_settings)
      UIRenderer.draw_widget(ui_renderer, self.rwaon_teammate_custom_widget)
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
          if content.timer_rush_string == "0:00" and not mod:get("always_show_timer") then
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
          if content.timer_rush_string == "0:00" and not mod:get("always_show_timer") then
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
          if content.timer_speedrun_string == "0:00" and not mod:get("always_show_timer") then
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
          if content.timer_speedrun_string == "0:00" and not mod:get("always_show_timer") then
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
          if content.timer_navmesh_string == "0:00" and not mod:get("always_show_timer") then
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
          if content.timer_navmesh_string == "0:00" and not mod:get("always_show_timer") then
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