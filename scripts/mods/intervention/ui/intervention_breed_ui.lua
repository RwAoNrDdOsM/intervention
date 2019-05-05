local mod = get_mod("intervention")
mod:dofile("scripts/settings/ui_player_portrait_frame_settings")
local definitions = mod:dofile("scripts/mods/intervention/ui/intervention_breed_ui_definitions")
local breed_textures = UISettings.breed_textures
InterventionBreedUI = class(InterventionBreedUI)

InterventionBreedUI.init = function (self, parent, ingame_ui_context)
	self._parent = parent
	self.ui_renderer = ingame_ui_context.ui_renderer
	self.input_manager = Managers.input
	self.player_manager = ingame_ui_context.player_manager
	self.peer_id = ingame_ui_context.peer_id
	self.world = ingame_ui_context.world_manager:world("level_world")
	self.render_settings = {
		snap_pixel_positions = true
	}

	self:create_ui_elements()

	self._intervention_breed_events = {}
	self._hash_order = {}
	self._hash_widget_lookup = {}
	self._animations = {}
	local event_manager = Managers.state.event

    event_manager:register(self, "add_breed_ui_info", "event_add_breed_info")
    mod:echo("InterventionBreedUI Initiated")
end

InterventionBreedUI.destroy = function (self)
	GarbageLeakDetector.register_object(self, "intervention_breed_ui")

	local event_manager = Managers.state.event

    event_manager:unregister("add_breed_ui_info", self)
    mod:echo("InterventionBreedUI Destroyed")
end

InterventionBreedUI.create_ui_elements = function (self)
	self.ui_scenegraph = UISceneGraph.init_scenegraph(definitions.scenegraph_definition)
	self.widgets = {
		rush = {
			rush_text = UIWidget.init(definitions.widget_definitions.rush_text),
			rush_text_shadow = UIWidget.init(definitions.widget_definitions.rush_text_shadow),
			icon_1 = UIWidget.init(definitions.widget_definitions.icon_1),
			icon_2 = UIWidget.init(definitions.widget_definitions.icon_2),
			icon_3 = UIWidget.init(definitions.widget_definitions.icon_3),
		},
		speedrunning = {
			speedrunning_text = UIWidget.init(definitions.widget_definitions.speedrunning_text),
			speedrunning_text_shadow = UIWidget.init(definitions.widget_definitions.speedrunning_text_shadow),
			icon_4 = UIWidget.init(definitions.widget_definitions.icon_4),
			icon_5 = UIWidget.init(definitions.widget_definitions.icon_5),
			icon_6 = UIWidget.init(definitions.widget_definitions.icon_6),
			icon_7 = UIWidget.init(definitions.widget_definitions.icon_7),
		}
	}

	UIRenderer.clear_scenegraph_queue(self.ui_renderer)
end

InterventionBreedUI.remove_event = function (self, index)
	local events = self._intervention_breed_events
	local event = table.remove(events, index)
	local widget = event.widget
end

InterventionBreedUI.add_event = function (self, breed_texture, event_type,...)
	--if not script_data.disable_reinforcement_ui then
		local events = self._intervention_breed_events
		local t = Managers.time:time("game")
		local increment_duration = UISettings.intervention_breed.increment_duration
		--local message_widgets = self.message_widgets
		--local unused_widgets = self._unused_widgets
		local widget = widget

		if event_type == "rush" then
			if self.widgets.rush.rush_text.content.rush_string == "" then
				self.widgets.rush.rush_text.content.rush_string = "Rush"
				self.widgets.rush.rush_text_shadow.content.rush_string = "Rush"
			end
			if self.widgets.rush.icon_1.content.icon_1 == nil then
				widget = self.widgets.rush.icon_1
			elseif self.widgets.rush.icon_2.content.icon_2 == nil then
				widget = self.widgets.rush.icon_2
			elseif self.widgets.rush.icon_3.content.icon_3 == nil then
				widget = self.widgets.rush.icon_3
			end
		elseif event_type == "speedrun" then
			if self.widgets.speedrunning.speedrunning_text.content.rush_string == "" then
				self.widgets.speedrunning.speedrunning_text.content.rush_string = "Speedrunning"
				self.widgets.speedrunning.speedrunning_text_shadow.content.rush_string = "Speedrunning"
			end
			if self.widgets.speedrunning.icon_5.content.icon_5 == nil then
				widget = self.widgets.speedrunning.icon_5
			elseif self.widgets.speedrunning.icon_6.content.icon_6 == nil then
				widget = self.widgets.speedrunning.icon_6
			elseif self.widgets.speedrunning.icon_7.content.icon_7 == nil then
				widget = self.widgets.speedrunning.icon_7
			end
		end

		if widget == nil then
			mod:echo("Intervention QoL: Unable to aquire a widger")
			return
		end

		local event = {
			text = "",
			shown_amount = 0,
			amount = 0,
			widget = widget,
			event_type = event_type,
			next_increment = t - increment_duration,
			is_local_player = is_local_player,
			data = {
				...
			}
		}
		local event_index = #events + 1

		table.insert(events, 1, event)

		local content = widget.content
		local style = widget.style
        self:_assign_portrait_texture(widget, "portrait_1", breed_texture)
    --end
end

local temp_portrait_size = {
	96,
	112
}

InterventionBreedUI._assign_portrait_texture = function (self, widget, pass_name, texture)
	widget.content[pass_name].texture_id = texture
	local portrait_size = table.clone(temp_portrait_size)

	if UIAtlasHelper.has_atlas_settings_by_texture_name(texture) then
		local texture_settings = UIAtlasHelper.get_atlas_settings_by_texture_name(texture)
		portrait_size[1] = texture_settings.size[1]
		portrait_size[2] = texture_settings.size[2]
	end

	local style = widget.style[pass_name]
	local portrait_offset = style.portrait_offset
	local offset = style.offset
	offset[1] = portrait_offset[1] - portrait_size[1] / 2
	offset[2] = portrait_offset[2] - portrait_size[2] / 2
	style.size = portrait_size
end

InterventionBreedUI.event_add_breed_info = function (self, breed_name, event_type)
	local breed_texture = breed_textures[breed_name]

	if not event_type or not breed_texture then
		return
	end
	self:add_event(breed_texture, event_type)
end

InterventionBreedUI.update = function (self, dt, t)
	local ui_renderer = self.ui_renderer
	local ui_scenegraph = self.ui_scenegraph
	local input_service = Managers.input:get_service("Player")
	local render_settings = self.render_settings
	--[[for name, animation in pairs(self._animations) do
		if self._animations[name] then
			if not UIAnimation.completed(animation) then
				UIAnimation.update(animation, dt)
			else
				self._animations[name] = nil
			end
		end
	end]]

	UIRenderer.begin_pass(ui_renderer, ui_scenegraph, input_service, dt, nil, render_settings)

	local events = self._intervention_breed_events
	local show_duration = UISettings.intervention_breed.show_duration
	local snap_pixel_positions = render_settings.snap_pixel_positions

	for index, event in ipairs(events) do
		local widget = event.widget
		local content = widget.content
		local style = widget.style
		local offset = widget.offset
        local event_type = event.event_type
		local removed = false

        
        if Managers.state.conflict and not event.remove_time then
            local conflict_director = Managers.state.conflict
            local timer = conflict_director:_next_intervention_time(t)
            if event_type == "rush" then
                show_duration = timer[1]
            elseif event_type == "speedrun" then
                show_duration = timer[2]
            elseif event_type == "navmesh" then
                show_duration = timer[3]
            end
        end

		if not event.remove_time then
			event.remove_time = t + show_duration + 1
		elseif event.remove_time < t then
			self:remove_event(index)

			removed = true
        end
        
		if not removed then
			UIRenderer.draw_widget(ui_renderer, widget)
		end
	end

	UIRenderer.end_pass(ui_renderer)
end