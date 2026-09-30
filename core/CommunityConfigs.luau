Raw JSON as a string, baby — JSON isn't valid Luau, so it rides inside [[ ]] and the client parses it. File structure:
return {
	{
		Name = "Legit Rifle",
		Author = "someone",
		Description = "Low FOV rifle setup.",
		Version = "1.0",
		Configuration = [[
      {"Aimbot_Enabled":{"Value":true,"Type":"Toggle"},"Aimbot_Type":{"Value":"Camera","Type":"Dropdown"}}
		]],
	},
}
