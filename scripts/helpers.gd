extends Node


func get_all_nodes_within(n: Node) -> Array:
	
	var result = []
	for node in n.get_children():
		result.append(node)
		if node.get_child_count() > 0:
			result.append_array(get_all_nodes_within(node))
	return result


func load_json_file(file: String):
	
	var f := File.new()
	var err := f.open(file, File.READ)
	
	if err:
		Status.post(tr("msg_file_read_fail") % [file.get_file(), err], Enums.MSG_ERROR)
		Status.post(tr("msg_debug_file_path") % file, Enums.MSG_DEBUG)
		return null
	
	var r := JSON.parse(f.get_as_text())
	f.close()
	
	if r.error:
		Status.post(tr("msg_json_parse_fail") % file.get_file(), Enums.MSG_ERROR)
		Status.post(tr("msg_debug_json_result") % [r.error, r.error_string, r.error_line], Enums.MSG_DEBUG)
		return null
	
	return r.result


func save_to_json_file(data, file: String) -> bool:
	
	var f := File.new()
	var err := f.open(file, File.WRITE)
	
	if err:
		Status.post(tr("msg_file_write_fail") % [file.get_file(), err], Enums.MSG_ERROR)
		Status.post(tr("msg_debug_file_path") % file, Enums.MSG_DEBUG)
		return false
	
	var text := JSON.print(data, "    ")
	f.store_string(text)
	f.close()
	
	return true


func filter_strings(filter_str: String, strings: Array, case_sensitive := false) -> Array:
	# Filters an array of strings and returns only the strings that match
	# the filter. Non-string array elements are ignored.
	
	var result := []
	
	for i in strings.size():
		var s = strings[i]
		if typeof(s) == TYPE_STRING:
			if not case_sensitive:
				filter_str = filter_str.to_lower()
				s = s.to_lower()
			if filter_str in s:
				result.push_back(strings[i])
	
	return result


func itemize_array(arr: Array, separator := ", ", bullet = "") -> String:
	# Creates a string listing the items of an array. Non-string array elements
	# will be ignored.
	
	var result := ""
	
	for s in arr:
		if typeof(s) != TYPE_STRING:
			continue
		result += bullet + s + separator
	
	result.trim_suffix(separator)
	return result
