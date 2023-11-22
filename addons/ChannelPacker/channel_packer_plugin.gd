@tool
extends EditorPlugin

var dock
var prefix = "./MarginContainer/VBoxContainer/"
var file_dialog: EditorFileDialog
var albedo_resource_picker: EditorResourcePicker
var height_resource_picker: EditorResourcePicker
var normal_resource_picker: EditorResourcePicker
var roughness_resource_picker: EditorResourcePicker

func _enter_tree():
	dock = preload("res://addons/ChannelPacker/channel_packer_dock.tscn").instantiate()
	add_control_to_dock(DOCK_SLOT_LEFT_UL, dock)

	# setup file dialog
	file_dialog = EditorFileDialog.new()
	var editor_interface = get_editor_interface()
	var base_control = editor_interface.get_base_control()
	file_dialog.set_filters(PackedStringArray(["*.png"]))
	file_dialog.set_file_mode(EditorFileDialog.FILE_MODE_SAVE_FILE)
	file_dialog.access = EditorFileDialog.ACCESS_FILESYSTEM
	file_dialog.connect("file_selected", _on_SaveFileDialog_file_selected)
	base_control.add_child(file_dialog)

	albedo_resource_picker = make_texture_picker(dock.get_node(prefix + "AlbedoHBox"), "Albedo")
	height_resource_picker = make_texture_picker(dock.get_node(prefix + "HeightHBox"), "Height")
	normal_resource_picker = make_texture_picker(dock.get_node(prefix + "NormalHBox"), "Normal")
	roughness_resource_picker = make_texture_picker(dock.get_node(prefix + "RoughnessHBox"), "Roughness")

	(dock.get_node(prefix + "PackButton") as Button).connect("pressed", _on_pack_button_pressed)
	hide_notifs()
	
func make_texture_picker(parent, label_text):
	var picker = EditorResourcePicker.new()
	picker.base_type = "Texture2D"
	picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(picker)
	return picker

func hide_notifs():
	(dock.get_node(prefix + "ErrorLabel") as RichTextLabel).visible = false
	(dock.get_node(prefix + "SuccessLabel") as RichTextLabel).visible = false

func show_error(text: String):
	push_error("ChannelPacker Error: " + text)
	(dock.get_node(prefix + "ErrorLabel") as RichTextLabel).visible = true
	(dock.get_node(prefix + "ErrorLabel") as RichTextLabel).text = text

func show_success(text: String):
	print("ChannelPacker Success: " + text)
	(dock.get_node(prefix + "SuccessLabel") as RichTextLabel).visible = true
	(dock.get_node(prefix + "SuccessLabel") as RichTextLabel).text = text

func pack_textures(rgb_image_resource: CompressedTexture2D, a_image_resource: CompressedTexture2D, dst_path: String):
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

		show_success("Packed to " + dst_path)
		output_image.save_png(dst_path)
	else:
		show_error("Failed to load one or more textures.")

var packing_albedo = false
var queue_pack_normal_roughness
func _on_pack_button_pressed():
	hide_notifs()
	var albedo_resource = albedo_resource_picker.edited_resource
	var height_resource = height_resource_picker.edited_resource
	var normal_resource = normal_resource_picker.edited_resource
	var roughness_resource = roughness_resource_picker.edited_resource

	if albedo_resource and height_resource:
		packing_albedo = true
		file_dialog.current_path = albedo_resource.resource_path.get_base_dir() + "/packed_albedo_height"
		file_dialog.title = "Save Packed Albedo/Height Texture"
		file_dialog.popup_centered_ratio()

		if normal_resource and roughness_resource:
			queue_pack_normal_roughness = true
	elif normal_resource and roughness_resource:
		packing_albedo = false
		file_dialog.current_path = normal_resource.resource_path.get_base_dir() + "/packed_normal_roughness"
		file_dialog.title = "Save Packed Normal/Roughness Texture"
		file_dialog.popup_centered_ratio()
	
	if not (albedo_resource and height_resource) and not (normal_resource and roughness_resource):
		show_error("Please select an albedo and height texture or a normal and roughness texture.")

# Signal handler for when a file is selected
func _on_SaveFileDialog_file_selected(dst_path):
	if packing_albedo:
		pack_textures(albedo_resource_picker.edited_resource, height_resource_picker.edited_resource, dst_path)
	else:
		pack_textures(normal_resource_picker.edited_resource, roughness_resource_picker.edited_resource, dst_path)
	
	if queue_pack_normal_roughness:
		queue_pack_normal_roughness = false
		packing_albedo = false
		file_dialog.current_path = normal_resource_picker.edited_resource.resource_path.get_base_dir() + "/packed_normal_roughness"
		file_dialog.title = "Save Packed Normal/Roughness Texture"
		file_dialog.popup_centered_ratio()

func _exit_tree():
	remove_control_from_docks(dock)
	dock.free()