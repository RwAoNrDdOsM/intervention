return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`intervention` mod must be lower than Vermintide Mod Framework in your launcher's load order.")

		new_mod("intervention", {
			mod_script       = "scripts/mods/intervention/intervention",
			mod_data         = "scripts/mods/intervention/intervention_data",
			mod_localization = "scripts/mods/intervention/intervention_localization",
		})
	end,
	packages = {
		"resource_packages/intervention/intervention",
	},
}
