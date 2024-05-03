@tool
extends InspectorGadgetBase
class_name GadgetEnum

var values: Dictionary = {}

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
	for v in values.keys():
		btn.add_item(v)
	btn.item_selected.connect(set_value)
	add_child(btn)

func set_value(value: int) -> void:
	set_node_value(value)

func populate_value(value) -> void:
	var btn: OptionButton = get_controls()[0]
	btn.select(value)

func depopulate_value() -> void:
	var btn: OptionButton = get_controls()[0]
	btn.select(-1)
