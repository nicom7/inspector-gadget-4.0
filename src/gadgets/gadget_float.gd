@tool
extends InspectorGadgetBase
class_name GadgetFloat

var range_hints: String

func _init(in_node_path: NodePath = NodePath(), in_subnames: String = ""):
	super._init(in_node_path, in_subnames)

static func supports_type(value) -> bool:
	if value is float:
		return true
	return false

func has_controls() -> bool:
	return has_node("SpinBox")

func get_controls() -> Array:
	return [$SpinBox]

func populate_controls() -> void:
	var spin_box = SpinBox.new()
	spin_box.name = "SpinBox"
	spin_box.min_value = -(1 << 31)
	spin_box.max_value = (1 << 31) - 1
	spin_box.allow_greater = true
	spin_box.allow_lesser = true
	spin_box.step = 0.01
	spin_box.tooltip_text = tooltip_text
	spin_box.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	spin_box.value_changed.connect(set_node_value)
	InspectorGadgetUtil.setup_range(spin_box, range_hints)
	add_child(spin_box)

func populate_value(value) -> void:
	var spin_box = get_controls()[0]
	if spin_box.value != value:
		spin_box.set_block_signals(true)
		spin_box.value = value
		spin_box.set_block_signals(false)
	spin_box.editable = editable

func depopulate_value() -> void:
	var spin_box = get_controls()[0]
	spin_box.set_block_signals(true)
	spin_box.value = 0.0
	spin_box.set_block_signals(false)
	spin_box.editable = false
