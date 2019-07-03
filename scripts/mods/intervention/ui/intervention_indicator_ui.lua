local mod = get_mod("intervention")
local definitions = mod:dofile("scripts/mods/intervention/ui/intervention_indicator_ui_definitions")
InterventionIndicatorUI = class(InterventionIndicatorUI)

InterventionIndicatorUI.init = function (self, parent, ingame_ui_context)
	self._parent = parent
	self.ui_renderer = ingame_ui_context.ui_renderer
	self.ingame_ui = ingame_ui_context.ingame_ui
	self.input_manager = ingame_ui_context.input_manager
	local world = ingame_ui_context.world_manager:world("level_world")
	self.wwise_world = Managers.world:wwise_world(world)

	self:create_ui_elements()
	--[[ WIP
	local event_manager = Managers.state.event
    event_manager:register(self, "set_current_intervention")
	]]
	rawset(_G, "intervention_indicator_ui", self)
end

InterventionIndicatorUI.create_ui_elements = function (self)
	self.ui_scenegraph = UISceneGraph.init_scenegraph(definitions.scenegraph_definition)
	self.area_text_box = UIWidget.init(definitions.widget_definitions.area_text_box)

	UIRenderer.clear_scenegraph_queue(self.ui_renderer)
end

InterventionIndicatorUI.destroy = function (self)
	--[[
	GarbageLeakDetector.register_object(self, "intervention_indicator_ui")
	local event_manager = Managers.state.event
    event_manager:unregister("set_current_intervention", self)
	]]
	rawset(_G, "intervention_indicator_ui", nil)
end

InterventionIndicatorUI.set_current_intervention = function (self, intervention)
	self.current_intervention = intervention
	local widget = self.area_text_box
	if intervention == "rush" then
		widget.style.text.text_color = Colors.get_color_table_with_alpha("red", 0)
		self.current_intervention = "rush_intervention"
	elseif intervention == "speedrun" then
		widget.style.text.text_color = Colors.get_color_table_with_alpha("cheeseburger", 0)
		self.current_intervention = "speed_run_intervention"
	elseif intervention == "navmesh" then
		widget.style.text.text_color = Colors.get_color_table_with_alpha("gray", 0)
		self.current_intervention = "outside_navmesh_intervention"
	else
		widget.style.text.text_color = Colors.get_color_table_with_alpha("white", 0)
	end
end

InterventionIndicatorUI.update = function (self, dt)
	local player_manager = Managers.player
	local local_player = player_manager:local_player()
	local player_unit = local_player.player_unit

    if Unit.alive(player_unit) then
        local player_hud_extension = ScriptUnit.extension(player_unit, "hud_system")
		local saved_intervention = self.saved_intervention
		local current_intervention = self.current_intervention
        
		if current_intervention ~= nil then --and current_intervention ~= saved_intervention
			self.current_intervention = nil
			local ui_settings = UISettings.intervention_indicator
			local widget = self.area_text_box
			widget.content.text = mod:localize(current_intervention) -- localize earlier?
			self.area_text_box_animation = UIAnimation.init(UIAnimation.function_by_time, widget.style.text.text_color, 1, 0, 255, ui_settings.fade_time, math.easeInCubic, UIAnimation.wait, ui_settings.wait_time, UIAnimation.function_by_time, widget.style.text.text_color, 1, 255, 0, ui_settings.fade_time, math.easeInCubic)
			self.area_text_box_shadow_animation = UIAnimation.init(UIAnimation.function_by_time, widget.style.text_shadow.text_color, 1, 0, 255, ui_settings.fade_time, math.easeInCubic, UIAnimation.wait, ui_settings.wait_time, UIAnimation.function_by_time, widget.style.text_shadow.text_color, 1, 255, 0, ui_settings.fade_time, math.easeInCubic)

			WwiseWorld.trigger_event(self.wwise_world, "hud_area_indicator")
		end
	end

	if self.area_text_box_animation == nil then
		return
	end

	self.area_text_box_animation = self:update_animation(self.area_text_box_animation, dt)
	self.area_text_box_shadow_animation = self:update_animation(self.area_text_box_shadow_animation, dt)

	self:draw(dt)
end

InterventionIndicatorUI.update_animation = function (self, animation, dt)
	if animation then
		UIAnimation.update(animation, dt)

		if UIAnimation.completed(animation) then
			return nil
		end

		return animation
	end
end

InterventionIndicatorUI.draw = function (self, dt)
	local ui_renderer = self.ui_renderer
	local ui_scenegraph = self.ui_scenegraph
	local input_service = self.input_manager:get_service("ingame_menu")

	UIRenderer.begin_pass(ui_renderer, ui_scenegraph, input_service, dt)
	UIRenderer.draw_widget(ui_renderer, self.area_text_box)
	UIRenderer.end_pass(ui_renderer)
end

-- WIP
-- Hook into the IngameHud.
--[[ =====================================================================================================================
local component = {
	class_name = InterventionIndicatorUI,
	filename = "scripts/mods/intervention/ui/intervention_indicator_ui",
	visibility_groups = {
	  --"mission_vote",
	  --"hero_selection_popup",
	  "in_endscreen",
	  --"in_menu",
	  --"tab_menu",
	  "game_mode_disable_hud",
	  --"cutscene",
	  "realism",
	  "dead",
	  "alive",
	},
  }
  
  
  local ingame_hud_definitions = local_require("scripts/ui/views/ingame_hud_definitions")
  
  -- Inject into the components list and lookup.
  local components = ingame_hud_definitions.components
  local index = #components + 1
  for i=1, #components do
	if components[i].class_name == "InterventionIndicatorUI" then
	  index = i
	  break
	end
  end
  components[index] = component
  ingame_hud_definitions.components_lookup["InterventionIndicatorUI"] = component
  ingame_hud_definitions.components_hud_scale_lookup["InterventionIndicatorUI"] = not not component.use_hud_scale
  
  -- Update the visibility groups.
  local visibility_groups_lookup = ingame_hud_definitions.visibility_groups_lookup
  --mod:dump(visibility_groups_lookup, "visibility_groups_lookup", 100)
  for _, group_name in ipairs(component.visibility_groups) do
	local visibility_group = visibility_groups_lookup[group_name]
	local visible_components = visibility_group.visible_components
	visible_components["InterventionIndicatorUI"] = true
  end]]