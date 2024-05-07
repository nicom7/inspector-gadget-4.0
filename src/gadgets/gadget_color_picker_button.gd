@tool
extends InspectorGadgetBase
class_name GadgetColorPickerButton

func _init(in_node_path: NodePath = NodePath(), in_subnames: String = ""):
	super._init(in_node_path, in_subnames)

static func supports_type(value) -> bool:
	return value is Color

func has_controls() -> bool:
	return has_node("ColorPickerButton")

func get_controls() -> Array:
	return [$ColorPickerButton]

func populate_controls() -> void:
	var color_picker: = ColorPickerButton.new()
	color_picker.name = "ColorPickerButton"
	color_picker.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	color_picker.custom_minimum_size = Vector2(32, 32)
	color_picker.tooltip_text = tooltip_text
	color_picker.color_changed.connect(set_node_value)
	add_child(color_picker)

func populate_value(value) -> void:
	var color_picker: = get_controls()[0] as ColorPickerButton
	color_picker.set_block_signals(true)
	color_picker.color = value
	color_picker.set_block_signals(false)

func depopulate_value() -> void:
	var color_picker: = get_controls()[0] as ColorPickerButton
	color_picker.set_block_signals(true)
	color_picker.color = Color.BLACK
	color_picker.set_block_signals(false)
