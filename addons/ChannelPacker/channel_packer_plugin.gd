@tool
extends EditorPlugin

var dock
var prefix = "./MarginContainer/VBoxContainer/"

func _enter_tree():
	dock = preload("res://addons/ChannelPacker/channel_packer_dock.tscn").instantiate()
	add_control_to_dock(DOCK_SLOT_LEFT_UL, dock)
	(dock.get_node(prefix + "PackAlbedoButton") as Button).connect("pressed", _on_pack_albedo_button_pressed)
	(dock.get_node(prefix + "PackNormalButton") as Button).connect("pressed", _on_pack_normal_button_pressed)
	hide_notifs()

func hide_notifs():
	(dock.get_node(prefix + "ErrorLabel") as RichTextLabel).visible = false
	(dock.get_node(prefix + "SuccessLabel") as RichTextLabel).visible = false

func show_error(text: String):
	(dock.get_node(prefix + "ErrorLabel") as RichTextLabel).visible = true
	(dock.get_node(prefix + "ErrorLabel") as RichTextLabel).text = text

func show_success(text: String):
	(dock.get_node(prefix + "SuccessLabel") as RichTextLabel).visible = true
	(dock.get_node(prefix + "SuccessLabel") as RichTextLabel).text = text

func pack_textures(base_path: String, rgb_ending: String, a_ending: String, dest_name: String):
	var rgb_path = ""
	var a_path = ""
	var error_text = ""
	var files = DirAccess.get_files_at(base_path)
	hide_notifs()

	for file in files:
		var noext = file.get_basename()
		if noext.ends_with(rgb_ending):
			rgb_path = base_path + file
		elif noext.ends_with(a_ending):
			a_path = base_path + file

	if rgb_path == "":
		error_text += "No texture ending in " + rgb_ending + " in path: " + base_path + "\n"
	if a_path == "":
		error_text += "No texture ending in " + a_ending + " in path: " + base_path + "\n"
	if error_text != "":
		show_error(error_text)
		print(error_text)
		return

	var rgb_image_resource: CompressedTexture2D = load(rgb_path) as CompressedTexture2D
	var a_image_resource: CompressedTexture2D = load(a_path) as CompressedTexture2D

	if not rgb_image_resource:
		error_text += "Failed to load texture: " + rgb_path + "\n"
	if not a_image_resource:
		error_text += "Failed to load texture: " + a_path + "\n"
	if error_text != "":
		show_error(error_text)
		print(error_text)
		return

	if rgb_image_resource and a_image_resource:
		var rgb_image = rgb_image_resource.get_image()
		var a_image = a_image_resource.get_image()

		var img_width = rgb_image.get_width()
		var img_height = rgb_image.get_height()

		var output_image = Image.create(img_width, img_height, false, Image.FORMAT_RGBA8)

		for x in range(img_width):
			for y in range(img_height):
				var rgb = rgb_image.get_pixel(x, y)
				var a = a_image.get_pixel(x, y).r

				output_image.set_pixel(x, y, Color(rgb.r, rgb.g, rgb.b, a))

		var dst_path = base_path + dest_name + ".png"
		show_success("Packed RGB channels from " + rgb_path + " and R from " + a_path + " into " + dst_path)
		output_image.save_png(base_path + dest_name)
	else:
		print("Failed to load one or more textures.")

func _on_pack_normal_button_pressed():
	var path = (dock.get_node(prefix + "FolderLineEdit") as LineEdit).text
	if not path.ends_with("/"):
		path += "/"

	pack_textures(path, "_normal", "_roughness", "normal_roughness_packed")

func _on_pack_albedo_button_pressed():
	var path = (dock.get_node(prefix + "FolderLineEdit") as LineEdit).text
	if not path.ends_with("/"):
		path += "/"

	pack_textures(path, "_albedo", "_height", "albedo_height_packed") 

func _exit_tree():
	remove_control_from_docks(dock)
	dock.free()