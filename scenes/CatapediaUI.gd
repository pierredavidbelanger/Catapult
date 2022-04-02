extends Control


var items_by_name := {}
var listed_items := []

onready var _list := $HBox/Items/ItemList
onready var _item_view := $HBox/Info/Tabs/Item
onready var _craft_view := $HBox/Info/Tabs/Craft
onready var _recipes_view := $HBox/Info/Tabs/Recipes
onready var _uncraft_view := $HBox/Info/Tabs/Disassembly
onready var _construct_view := $HBox/Info/Tabs/Construction


func _ready() -> void:
	
	Catapedia.load_game_data()
	
	for item in Catapedia.items.values():
		if "name" in item:
			items_by_name[item["name"]] = item["id"]
	
	_populate_item_list()


func _populate_item_list(filter_str := "") -> void:
	
	_list.clear()
	
	if filter_str == "":
		listed_items = items_by_name.keys()
	else:
		listed_items = Helpers.filter_strings(filter_str, items_by_name.keys())
	
	listed_items.sort()
	for i in listed_items.size():
		_list.add_item(listed_items[i])


func _on_ItemList_item_selected(index: int) -> void:
	
	var item_id = items_by_name[listed_items[index]]
	_populate_item_info(item_id)
	_populate_crafting_info(item_id)
	_populate_recipes_info(item_id)
	_populate_disassembly_info(item_id)
	

func _populate_item_info(item_id: String) -> void:
	
	var item = Catapedia.items[item_id]
	var text := "[table=2]"
	
	if "weight" in item:
		text += "[cell]Weight:[/cell][cell]%s[/cell]" % item["weight"]
	if "volume" in item:
		text += "[cell]Volume:[/cell][cell]%s[/cell]" % item["volume"]
	if "material" in item:
		var mats := []
		for m in item["material"]:
			mats.push_back(Catapedia.items[m]["name"])
		text += "[cell]Materials:[/cell][cell]%s[/cell]" % Helpers.itemize_array(mats)
	if "flags" in item:
		text += "[cell]Flags:[/cell][cell]%s[/cell]" % Helpers.itemize_array(item["flags"])
	if "qualities" in item:
		var strings := []
		for q in item["qualities"]:
			strings.push_back(Catapedia.tool_qualities[q[0]] + " " + str(q[1]))
		text += "[cell]Tool qualities:[/cell][cell]%s[/cell]" % Helpers.itemize_array(strings)
	
	text += "[/table]"
	_item_view.bbcode_text = text + "\n\n" + JSON.print(item, "  ")


func _populate_crafting_info(item_id: String) -> void:
	
	var name = Catapedia.items[item_id]["name"]
	if item_id in Catapedia.recipes:
		var recipes = Catapedia.recipes[item_id]
		_craft_view.bbcode_text = JSON.print(recipes, "  ")
	else:
		_craft_view.bbcode_text = "[b]%s[/b] is not craftable." % name


func _populate_recipes_info(item_id: String) -> void:
	
	var name  = Catapedia.items[item_id]["name"]
	var recipes := Catapedia.get_recipes_with_item(item_id)
	var recipe_names := []
	
	for id in recipes:
		recipe_names.push_back(Catapedia.items[id]["name"])
	recipe_names.sort()
	
	if recipes.size() > 0:
		_recipes_view.bbcode_text = "[b]%s[/b] is used in %s recipes:\n\n" % [name, recipes.size()] 
		_recipes_view.bbcode_text += Helpers.itemize_array(recipe_names, "\n", " • [url]", "[/url]")
	else:
		_recipes_view.bbcode_text = "[b]%s[/b] is not used in any recipes." % name


func _populate_disassembly_info(item_id: String) -> void:
	
	if item_id in Catapedia.recipes_uncraft:
		_uncraft_view.bbcode_text = JSON.print(Catapedia.recipes_uncraft[item_id], "  ")
	else:
		_uncraft_view.bbcode_text = "This item cannot be disassembled."


func _populate_construction_info(item_id: String) -> void:
	
	pass


func _on_FilterField_text_changed(new_text: String) -> void:
	
	_populate_item_list(new_text)
