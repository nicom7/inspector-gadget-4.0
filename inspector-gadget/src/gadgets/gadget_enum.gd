@tool
extends InspectorGadgetBase
class_name GadgetEnum

var enum_data: Dictionary = {}

func _init(in_node_path: NodePath = NodePath(), in_subnames: String = ""):
	super._init(in_node_path, in_subnames)

static func supports_type(value) -> bool:
	return (value is int)

func has_controls() -> bool:
	return has_node("OptionButton")

func get_controls() -> Array:
	return [$OptionButton]

func populate_controls() -> void:
	var btn = OptionButton.new()
	btn.name = "OptionButton"
	btn.clip_text = true
	btn.size_flags_horizontal = SIZE_EXPAND_FILL
	for v in enum_data.keys():
		btn.add_item(v)
	btn.item_selected.connect(set_value)
	add_child(btn)

func set_value(index: int) -> void:
	var values: = enum_data.values()
	if index >= 0:
		set_node_value(values[index])
	else:
		set_node_value(0)

func populate_value(value) -> void:
	var btn: OptionButton = get_controls()[0]
	var values: = enum_data.values()
	var index = values.find(value)
	btn.set_block_signals(true)
	btn.select(index)
	btn.set_block_signals(false)

func depopulate_value() -> void:
	var btn: OptionButton = get_controls()[0]
	btn.set_block_signals(true)
	btn.select(-1)
	btn.set_block_signals(false)

