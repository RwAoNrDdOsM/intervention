local_require("scripts/ui/ui_widgets")

local FONT_SIZE = 18
local scenegraph_definition = {
	root = {
		scale = "hud_fit",
		position = {
			0,
			0,
			UILayer.hud
		},
		size = {
			1920,
			1080
		}
	},
	message_animated = {
		vertical_alignment = "top",
		parent = "root",
		horizontal_alignment = "right",
		position = {
			-190 - 200,
			-60,
			1
		},
		size = {
			0,
			0
		}
	}
}

local widget_definitions = {
	message_animated = {
		scenegraph_id = "message_animated",
		element = {
			passes = {
				{
					style_id = "rush_text",
					pass_type = "text",
					text_id = "rush_string",
					retained_mode = false,
					content_check_function = function (content)
						if content.rush_string == "" then
							return false
						end

						return true
					end
				},
				{
					style_id = "rush_text_shadow",
					pass_type = "text",
					text_id = "rush_string",
					retained_mode = false,
					content_check_function = function (content)
						if content.rush_string == "" then
							return false
						end

						return true
					end
				},
				{
					style_id = "speedrunning_text",
					pass_type = "text",
					text_id = "speedrunning_string",
					retained_mode = false,
					content_check_function = function (content)
						if content.speedrun_string == "" then
							return false
						end

						return true
					end
				},
				{
					style_id = "speedrunning_text_shadow",
					pass_type = "text",
					text_id = "speedrunning_string",
					retained_mode = false,
					content_check_function = function (content)
						if content.speedrun_string == "" then
							return false
						end

						return true
					end
				},
				{
					pass_type = "texture",
					style_id = "icon_1",
					texture_id = "icon_1",
					content_check_function = function (content)
						if not content.icon_1 then
							return false
						end

						return true
					end
				},
				{
					pass_type = "texture",
					style_id = "icon_2",
					texture_id = "icon_2",
					content_check_function = function (content)
						if not content.icon_2 then
							return false
						end

						return true
					end
				},
				{
					pass_type = "texture",
					style_id = "icon_3",
					texture_id = "icon_3",
					content_check_function = function (content)
						if not content.icon_3 then
							return false
						end

						return true
					end
				},
				{
					pass_type = "texture",
					style_id = "icon_4",
					texture_id = "icon_4",
					content_check_function = function (content)
						if not content.icon_4 then
							return false
						end

						return true
					end
				},
				{
					pass_type = "texture",
					style_id = "icon_5",
					texture_id = "icon_5",
					content_check_function = function (content)
						if not content.icon_5 then
							return false
						end

						return true
					end
				},
				{
					pass_type = "texture",
					style_id = "icon_6",
					texture_id = "icon_6",
					content_check_function = function (content)
						if not content.icon_6 then
							return false
						end

						return true
					end
				},
				{
					pass_type = "texture",
					style_id = "icon_7",
					texture_id = "icon_7",
					content_check_function = function (content)
						if not content.icon_7 then
							return false
						end

						return true
					end
        },
			}
		},
		content = {
			rush_string = "",
			speedrun_string = "",
		},
		style = {
			rush_text = {
				vertical_alignment = "center",
				font_type = "hell_shark",
				font_size = 16,
				horizontal_alignment = "center",
				text_color = Colors.get_table("red"),
				offset = {
					0,
					0,
					0
				}
			},
			rush_text_shadow = {
				vertical_alignment = "center",
				font_type = "hell_shark",
				font_size = 16,
				horizontal_alignment = "center",
				text_color = Colors.get_table("black"),
				offset = {
					0 + 2,
					0 - 2,
					0
				}
			},
			speedrunning_text = {
				vertical_alignment = "center",
				font_type = "hell_shark",
				font_size = 16,
				horizontal_alignment = "center",
				text_color = Colors.get_table("red"),
				offset = {
					-100,
					0,
					0
				}
			},
			speedrunning_text_shadow = {
				vertical_alignment = "center",
				font_type = "hell_shark",
				font_size = 16,
				horizontal_alignment = "center",
				text_color = Colors.get_table("black"),
				offset = {
					-100 + 2,
					0 - 2,
					0
				}
			},
			icon_1 = {
				size = {
					50,
					50
				},
				offset = {
					0,
					-40,
					0
				},
				color = Colors.get_table("red")
			},
			icon_2 = {
				size = {
					50,
					50
				},
				offset = {
					0,
					-40 - 80,
					0
				},
				color = Colors.get_table("red")
			},
			icon_3 = {
				size = {
					50,
					50
				},
				offset = {
					0,
					-40 - 80 - 80,
					0
				},
				color = Colors.get_table("red")
			},
			icon_4 = {
				size = {
					50,
					50
				},
				offset = {
					-100,
					-40,
					0
				},
				color = Colors.get_table("cheeseburger")
			},
			icon_5 = {
				size = {
					50,
					50
				},
				offset = {
					-100,
					-40 - 80,
					0
				},
				color = Colors.get_table("cheeseburger")
			},
			icon_6 = {
				size = {
					50,
					50
				},
				offset = {
					-100,
					-40 - 80 - 80,
					0
				},
				color = Colors.get_table("cheeseburger")
			},
			icon_7 = {
				size = {
					50,
					50
				},
				offset = {
					-100,
					-40 - 80 - 80,
					0
				},
				color = Colors.get_table("cheeseburger")
			},
		}
	}
}

local function create_reinforcement_widget(scenegraph_id, frame_settings_name, scale, retained_mode)
	scale = scale or 1
	local frame_settings = UIPlayerPortraitFrameSettings[frame_settings_name]
	local default_color = {
		255,
		255,
		255,
		255
	}
	local default_offset = {
		0,
		0,
		0
	}
	local widget = {
		element = {}
	}
	local passes = {}
	local content = {
		scale = scale,
		frame_settings_name = frame_settings_name
	}
	local style = {}
	local texte_style_ids = {}
	local widget_length = 150
	local center_icon_name = "icon"
	passes[#passes + 1] = {
		pass_type = "texture",
		texture_id = center_icon_name,
		style_id = center_icon_name,
		retained_mode = retained_mode
	}
	content[center_icon_name] = "icons_placeholder"
	style[center_icon_name] = {
		color = table.clone(default_color),
		offset = {
			widget_length / 2 - 20 - 8,
			-20,
			2
		},
		size = {
			40,
			40
		}
	}
	texte_style_ids[#texte_style_ids + 1] = center_icon_name
	local background_name = "background"
	passes[#passes + 1] = {
		pass_type = "texture",
		texture_id = background_name,
		style_id = background_name,
		retained_mode = retained_mode
	}
	content[background_name] = "reinforcement_background"
	style[background_name] = {
		color = table.clone(default_color),
		offset = {
			widget_length / 2 - 116,
			-34,
			0
		},
		size = {
			232,
			68
		}
	}
	texte_style_ids[#texte_style_ids + 1] = background_name
	local arrow_name = "arrow"
	passes[#passes + 1] = {
		pass_type = "texture",
		texture_id = arrow_name,
		style_id = arrow_name,
		retained_mode = retained_mode
	}
	content[arrow_name] = "reinforcement_arrow"
	style[arrow_name] = {
		color = table.clone(default_color),
		offset = {
			widget_length / 2 - 8,
			-13,
			1
		},
		size = {
			35,
			26
		}
	}
	texte_style_ids[#texte_style_ids + 1] = arrow_name

	local temp_portrait_size = {
		96,
		112
	}
	for i = 1, 2, 1 do
		local portrait_offset = {
			(i - 1) * widget_length,
			0,
			3
		}
		local portrait_texture = "icons_placeholder"
		local portrait_size = {
			temp_portrait_size[1] * scale,
			temp_portrait_size[2] * scale
		}
		local offset = table.clone(default_offset)
		offset[1] = portrait_offset[1] - portrait_size[1] / 2 + offset[1] * scale
		offset[2] = portrait_offset[2] - portrait_size[2] / 2 + offset[2] * scale
		offset[3] = portrait_offset[3]
		local portrait_name = "portrait_" .. i
		passes[#passes + 1] = {
			pass_type = "texture_uv",
			content_id = portrait_name,
			style_id = portrait_name,
			retained_mode = retained_mode
		}

		if i ~= 1 or not {
			{
				0,
				0
			},
			{
				1,
				1
			}
		} then
			local uvs = {
				{
					1,
					0
				},
				{
					0,
					1
				}
			}
		end

		content[portrait_name] = {
			texture_id = portrait_texture,
			uvs = uvs
		}
		style[portrait_name] = {
			color = default_color,
			offset = offset,
			size = portrait_size,
			portrait_offset = portrait_offset
		}
		texte_style_ids[#texte_style_ids + 1] = portrait_name
	end

	content.texte_style_ids = texte_style_ids
	widget.element.passes = passes
	widget.content = content
	widget.style = style
	widget.offset = {
		0,
		0,
		0
	}
	widget.scenegraph_id = scenegraph_id

	return widget
end

local message_widgets = {}
local MAX_NUMBER_OF_MESSAGES = 3
for i = 1, MAX_NUMBER_OF_MESSAGES, 1 do
	local widget = create_reinforcement_widget("message_animated", "positive_reinforcement", 1)
	message_widgets[i] = widget
end

return {
	scenegraph_definition = scenegraph_definition,
	animated_message_widget = widget_definitions.message_animated,
	message_widgets = message_widgets,
}
