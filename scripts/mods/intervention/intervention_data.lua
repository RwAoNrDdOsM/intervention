local mod = get_mod("intervention")

return {
	name = "intervention",
	description = mod:localize("mod_description"),
	is_togglable = true,
	options = {
        widgets = {
			{
				setting_id    = "loneliness",
				type          = "dropdown",
				default_value = "both",
				options = {
				  {text = "disabled",   value = "disabled", show_widgets = {}},
				  {text = "both",   value = "both", show_widgets = {1,2,3,4,5,6,7}},
				  {text = "player",   value = "player", show_widgets = {1,2,3,4,7}},
				  {text = "team", value = "team", show_widgets = {1,2,5,6,7}
				  },
				},
				sub_widgets = {
					{
						setting_id    = "turn_red",
						type          = "checkbox",
						default_value = true,
					},
					{
						setting_id    = "always_show_loneliness",
						type          = "checkbox",
						default_value = true,
					},
					{
						setting_id      = "loneliness_x",
						type            = "numeric",
						default_value   = 0,
						range           = {-2500, 2500},
						unit_text = "px",                        
					},
					{
						setting_id      = "loneliness_y",
						type            = "numeric",
						default_value   = 0,
						range           = {-2500, 2500},
						unit_text = "px",                             
					},
					{
						setting_id      = "loneliness_x_team",
						type            = "numeric",
						default_value   = 0,
						range           = {-2500, 2500},
						unit_text = "px",                              
					},
					{
						setting_id      = "loneliness_y_team",
						type            = "numeric",
						default_value   = 0,
						range           = {-2500, 2500},
						unit_text = "px",                             
					},
					{
						setting_id      = "loneliness_font_size",
						type            = "numeric",
						default_value   = 22,
						range           = {1, 32},
						unit_text = "px",                              
					},
				},
			},
			{
				setting_id    = "timers",
				type          = "checkbox",
				default_value = true,
				sub_widgets   = {
					{
						setting_id    = "always_show_timer",
						type          = "checkbox",
						default_value = false,
					},
					{
						setting_id      = "timer_x",
						type            = "numeric",
						default_value   = 0,
						range           = {-2500, 2500},
						unit_text = "px",                              
					},
					{
						setting_id      = "timer_y",
						type            = "numeric",
						default_value   = 0,
						range           = {-2500, 2500},
						unit_text = "px",                             
					},
					{
						setting_id      = "timer_font_size",
						type            = "numeric",
						default_value   = 22,
						range           = {1, 32},
						unit_text = "px",                              
					},
					{
						setting_id      = "timer_spacing",
						type            = "numeric",
						default_value   = 24,
						range           = {0, 48},
						unit_text = "px",                              
					},
				}
			  }
        }
    },
}
