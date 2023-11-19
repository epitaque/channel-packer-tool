@tool
extends EditorPlugin

var dock
func _enter_tree():
	dock = preload("res://addons/ChannelPacker/channel_packer_dock.tscn").instantiate()
	add_control_to_dock(DOCK_SLOT_LEFT_UL, dock)
	(dock.get_node("./Button") as Button).connect("pressed", _on_button_pressed)

func _on_button_pressed():
	print("Button pressed!")
	var path = (dock.get_node("./TextEdit") as TextEdit).text
	var error_node = dock.get_node("./ErrorLabel") as RichTextLabel
	print(path)
	var files_exist = check_texture_files(path, error_node)
	if not files_exist:
		print("ERROR: some files are missing")
		return

	var albedo_path
	var height_path
	var normal_path
	var roughness_path
	var files = DirAccess.get_files_at(path)
	print(files)

	for file in files:
		if file.ends_with("_albedo.png"):
			albedo_path = path + "/" + file
		elif file.ends_with("_height.png"):
			height_path = path + "/" + file
		elif file.ends_with("_normal.png"):
			normal_path = path + "/" + file
		elif file.ends_with("_roughness.png"):
			roughness_path = path + "/" + file

	print("here!")
	var image_resource = load(albedo_path)
	if image_resource:
		print("loaded  " + albedo_path)
	else:
		print("failed to load  " + albedo_path)
	return

	var width = im.get_width()
	var height = im.get_height()
	
	var output_image = Image.new()
	output_image.create(width, height, false, Image.FORMAT_RGBA8)
	output_image.fill(Color(0, 0, 0, 1))

	for x in range(width):
		for y in range(height):
			var albedo = im.get_pixel(x, y)
			output_image.set_pixel(x, y, Color(albedo.r, albedo.g, albedo.b, 1))
	var dst_albedo_packed_path = path + "/albedo_packed.png"
	print("Saving image to " + dst_albedo_packed_path)
	return
	err = output_image.save_png(path + "/albedo_packed.png")
	# 	var im = Image.new()
	# var err = im.load(fpath)
	# if err != OK:
	# 	print("ERROR: couldn't load image '", fpath, "', error ", err)
	# 	return	


func check_texture_files(directory_path: String, error_label: RichTextLabel) -> bool:
	var error_message = ""

	# Ensure the provided path is a directory
	if not DirAccess.dir_exists_absolute(directory_path):
		error_message = "The provided path is not a directory."
	else:
		# List of expected file suffixes
		var expected_suffixes = ["_albedo.png", "_height.png", "_normal.png", "_roughness.png"]
		# Check for each file
		var files = DirAccess.get_files_at(directory_path)
		for suffix in expected_suffixes:
			var file_found = false
			for file in files:
				if file.ends_with(suffix):
					file_found = true
					break
			if not file_found:
				error_message += "File not found: *" + suffix + "\n"
			

	# Update the ErrorNode with the error message or clear it if there are no errors
	error_label.text = error_message
	return error_message == ""

func _exit_tree():
	# Clean-up of the plugin goes here.
	# Remove the dock.
	remove_control_from_docks(dock)
	# Erase the control from the memory.
	dock.free()