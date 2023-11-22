@tool
extends EditorPlugin

var dock
var prefix = "./MarginContainer/VBoxContainer/"
var file_dialog: EditorFileDialog
var rgb_resource_picker: EditorResourcePicker
var a_resource_picker: EditorResourcePicker

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

	# setup resource pickers
	rgb_resource_picker = EditorResourcePicker.new()
	a_resource_picker = EditorResourcePicker.new()
	rgb_resource_picker.base_type = "Texture2D"
	a_resource_picker.base_type = "Texture2D"
	rgb_resource_picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	a_resource_picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	dock.get_node(prefix + "RGBChannelHBox").add_child(rgb_resource_picker)
	dock.get_node(prefix + "AlphaChannelHBox").add_child(a_resource_picker)
	(dock.get_node(prefix + "PackButton") as Button).connect("pressed", _on_pack_button_pressed)
	hide_notifs()
	

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

func pack_textures(dst_path: String):
	hide_notifs()

	var rgb_image_resource: CompressedTexture2D = rgb_resource_picker.edited_resource as CompressedTexture2D
	var a_image_resource: CompressedTexture2D = a_resource_picker.edited_resource as CompressedTexture2D

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

func _on_pack_button_pressed():
	if not rgb_resource_picker.edited_resource:
		show_error("No RGB texture selected.")
		return
	if not a_resource_picker.edited_resource:
		show_error("No Alpha texture selected.")
		return

	file_dialog.current_path = rgb_resource_picker.edited_resource.resource_path.get_base_dir() + "/"
	file_dialog.popup_centered_ratio()

# Signal handler for when a file is selected
func _on_SaveFileDialog_file_selected(dst_path):
	pack_textures(dst_path)

func _exit_tree():
	remove_control_from_docks(dock)
	dock.free()