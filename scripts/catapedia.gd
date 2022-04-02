extends Node


var items: Dictionary
var items_abstract: Dictionary
var recipes: Dictionary
var recipes_abstract: Dictionary
var recipes_uncraft: Dictionary
var craft_reqs: Dictionary
var skill_names: Dictionary
var tool_qualities: Dictionary

func load_game_data() -> void:
	
	Status.post("Loading game data...")
	_load_requirements()
	_load_items()
	_load_recipes()
	_load_skills()
	_load_qualities() 


func get_recipes_with_item(item_id: String) -> Array:
	
	var list := []
	
	for recipe_set in recipes.values():
		for recipe in recipe_set:
			if not recipe["result"] in items:
				continue
			if not "components" in recipe:
				continue
			for component_set in recipe["components"]:
				for component in component_set:
					if (component[0] == item_id) and (not recipe["result"] in list):
						list.push_back(recipe["result"])
	
	return list


func _load_items() -> void:
	
	items = {}
	items_abstract = {}
	var json_dir := Paths.game_dir.plus_file("data/json/items")
	var json_files := FS.list_dir(json_dir, true, true)
	json_files.push_back(Paths.game_dir.plus_file("data/json/materials.json"))

	for file in json_files:
		
		if file.get_extension() != "json":
			continue
		
		var parsed = Helpers.load_json_file(file)
		for item in parsed:
			if "id" in item:
				items[item["id"]] = item
			elif "abstract" in item:
				items_abstract[item["abstract"]] = item
		
	for id in items.keys():
		items[id] = _process_item_info(items[id])
	
	Status.post("Loaded %s inventory items." % items.size())


func _load_recipes() -> void:
	
	recipes = {}
	recipes_uncraft = {}
	var counter := 0
	var json_dirs := [
		Paths.game_dir.plus_file("data/json/recipes"),
		Paths.game_dir.plus_file("data/json/uncraft"),
	]
	var json_files := []
	for dir in json_dirs:
		for file in FS.list_dir(dir, true):
			json_files.push_back(dir.plus_file(file))
	
	for file in json_files:
		
		if file.get_extension() != "json":
			continue
		
		var parsed = Helpers.load_json_file(file)
		for recipe in parsed:
			if "type" in recipe:
				
				if recipe["type"] == "recipe":
					if "result" in recipe:
						var id = recipe["result"]
						if id in recipes:
							recipes[id].push_back(recipe)
						else:
							recipes[id] = [recipe]
						counter += 1
						if ("reversible" in recipe) and (recipe["reversible"]):
							recipes_uncraft[id] = recipe
					elif "abstract" in recipe:
						recipes_abstract[recipe["abstract"]] = recipe
					
				elif recipe["type"] == "uncraft":
					if "result" in recipe:
						recipes_uncraft[recipe["result"]] = recipe
						counter += 1
					elif "abstract" in recipe:
						recipes_abstract[recipe["abstract"]] = recipe
	
	for id in recipes.keys():
		for i in recipes[id].size():
			recipes[id][i] = _process_recipe_info(recipes[id][i])
	
	Status.post("Loaded %s crafting recipes." % counter)


func _load_requirements() -> void:
	
	craft_reqs = {}
	var json_dir := Paths.game_dir.plus_file("data/json/requirements")
	
	for file in FS.list_dir(json_dir, true):
	
		if file.get_extension() != "json":
			continue
		
		var parsed = Helpers.load_json_file(json_dir.plus_file(file))
		for req in parsed:
			craft_reqs[req["id"]] = req


func _load_skills() -> void:
	
	skill_names = {}
	var data = Helpers.load_json_file(Paths.game_dir.plus_file("data/json/skills.json"))
	for skill in data:
		skill_names[skill["id"]] = skill["name"]["str"]


func _load_qualities() -> void:
	
	tool_qualities = {}
	var data = Helpers.load_json_file(Paths.game_dir.plus_file("data/json/tool_qualities.json"))
	for quality in data:
		tool_qualities[quality["id"]] = quality["name"]["str"]


func _process_item_info(item: Dictionary) -> Dictionary:
	
	if "name" in item:
		if typeof(item["name"]) == TYPE_DICTIONARY:
			item["name"] = item["name"].values()[0]
	
	if "copy-from" in item:
		item = _do_item_copy_from(item)
	
	return item


func _process_recipe_info(recipe: Dictionary) -> Dictionary:
	
	if "copy-from" in recipe:
		recipe = _do_recipe_copy_from(recipe)
	
	if "using" in recipe:
		recipe = _expand_reqs_in_recipe(recipe)
	
	return recipe


func _do_item_copy_from(item: Dictionary) -> Dictionary:
	
	var super_id = item["copy-from"]
	var super: Dictionary
	if super_id in items:
		super = items[super_id]
	elif super_id in items_abstract:
		super = items_abstract[super_id]
	
	if "copy-from" in super:
		super = _do_item_copy_from(super)
	
	item.erase("copy-from")
	for field in super.keys():
		if not field in item:
			item[field] = super[field]
	
	return item


func _do_recipe_copy_from(recipe: Dictionary) -> Dictionary:
	
	var super_id = recipe["copy-from"]
	var super: Dictionary
	
	if super_id in recipes:
		super = recipes[super_id][0]
	elif super_id in recipes_abstract:
		super = recipes_abstract[super_id]
	
	if "copy-from" in super:
		super = _do_recipe_copy_from(super)
	
	recipe.erase("copy-from")
	for field in super.keys():
		if not field in recipe:
			recipe[field] = super[field]
	
	return recipe


func _expand_reqs_in_recipe(recipe: Dictionary) -> Dictionary:
	
	for using_item in recipe["using"]:
		var req_id = using_item[0]
		var amt := int(using_item[1])
		var req = craft_reqs[req_id]
	
		if "qualities" in req:
			if "qualities" in recipe:
				recipe["qualities"].append_array(req["qualities"])
			else:
				recipe["qualities"] = req["qualities"].duplicate()

		if "tools" in req:
			if "tools" in recipe:
				recipe["tools"].append_array(req["tools"])
			else:
				recipe["qualities"] = req["tools"].duplicate()

		if "components" in req:
			var comp = req["components"].duplicate()
			for line in comp:
				for item in line:
					item[1] = int(item[1]) * amt

			if "components" in recipe:
				recipe["components"].append_array(comp)
			else:
				recipe["components"] = comp
		
	recipe.erase("using")
	return recipe
