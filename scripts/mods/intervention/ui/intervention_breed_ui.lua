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
	UIRenderer.clear_scenegraph_queue(self.ui_renderer)

	self.ui_scenegraph = UISceneGraph.init_scenegraph(definitions.scenegraph_definition)
	self.message_widgets = {}

	for _, widget in pairs(definitions.message_widgets) do
		self.message_widgets[#self.message_widgets + 1] = UIWidget.init(widget)
	end

	self._unused_widgets = table.clone(self.message_widgets)
	mod:echo("InterventionBreedUI Created UI Elements")
end

InterventionBreedUI.remove_event = function (self, index)
	local events = self._intervention_breed_events
	local event = table.remove(events, index)
	local widget = event.widget
	local unused_widgets = self._unused_widgets
	unused_widgets[#unused_widgets + 1] = widget
end

InterventionBreedUI.add_event = function (self, breed_texture, event_type,...)
	--if not script_data.disable_reinforcement_ui then
		local events = self._intervention_breed_events
		local t = Managers.time:time("game")
		local increment_duration = UISettings.intervention_breed.increment_duration
		local message_widgets = self.message_widgets
		local unused_widgets = self._unused_widgets

		if #unused_widgets == 0 then
			self:remove_event(#events)
        end
        
		local widget = table.remove(unused_widgets, 1)
		local offset = widget.offset
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
                content.text = "Rush"
                style.text = Colors.get_table("red") 
            elseif event_type == "speedrun" then
                show_duration = timer[2]
                content.text = "Speedrunning"
                style.text = Colors.get_table("cheeseburger")
            elseif event_type == "navmesh" then
                show_duration = timer[3]
                content.text = "NavMesh"
                style.text = Colors.get_table("gray")
            end
        end

		if not event.remove_time then
			event.remove_time = t + show_duration
		elseif event.remove_time < t then
			self:remove_event(index)

			removed = true
        end
        
		if not removed then
			local step_size = -80
			local new_height_offset = -((index - 1) * step_size)
			local diff = math.abs(math.abs(offset[2]) - math.abs(new_height_offset))

			if new_height_offset < offset[2] then
				local speed = 400
				offset[2] = math.max(offset[2] - dt * speed, new_height_offset)
			else
				offset[2] = new_height_offset
			end

			local time_left = event.remove_time - t
			local fade_duration = UISettings.intervention_breed.fade_duration
			local fade_out_progress = 0

			if fade_duration < time_left then
				fade_out_progress = math.clamp((show_duration - time_left) / fade_duration, 0, 1)
				offset[1] = -(math.easeInCubic(1 - fade_out_progress) * 35)
			else
				fade_out_progress = math.clamp(time_left / fade_duration, 0, 1)
			end

			local anim_progress = math.easeOutCubic(fade_out_progress)
			local alpha = 255 * anim_progress
			local texte_style_ids = content.texte_style_ids

			for _, style_id in ipairs(texte_style_ids) do
				style[style_id].color[1] = alpha
			end

			render_settings.snap_pixel_positions = time_left <= fade_duration

			UIRenderer.draw_widget(ui_renderer, widget)

			render_settings.snap_pixel_positions = snap_pixel_positions
		end
	end

	UIRenderer.end_pass(ui_renderer)
end