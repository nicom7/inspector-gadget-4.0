@tool
extends InspectorGadgetBase
class_name GadgetVector2

func _init(in_node_path: NodePath = NodePath(), in_subnames: String = ""):
	super._init(in_node_path, in_subnames)

func set_node_path(new_node_path: NodePath):
	super.set_node_path(new_node_path)

	if not has_controls():
		return

	var hbox = get_controls()[0]
	var float_gadget_x = hbox.get_node("FloatGadgetX")
	var float_gadget_y = hbox.get_node("FloatGadgetY")
	float_gadget_x.node_path = node_path
	float_gadget_y.node_path = node_path

func set_subnames(new_subnames: String):
	super.set_subnames(new_subnames)

	if not has_controls():
		return

	var hbox = get_controls()[0]
	var float_gadget_x = hbox.get_node("FloatGadgetX")
	var float_gadget_y = hbox.get_node("FloatGadgetY")
	float_gadget_x.subnames = subnames + ":x"
	float_gadget_y.subnames = subnames + ":y"

static func supports_type(value) -> bool:
	if value is Vector2:
		return true
	return false

func has_controls() -> bool:
	return has_node("HBoxContainer")

func get_controls() -> Array:
	return [$HBoxContainer]

func populate_controls() -> void:
	var label_x = Label.new()
	label_x.text = "X"

	var label_y = Label.new()
	label_y.text = "Y"

	var float_gadget_x = GadgetFloat.new(NodePath("../../" + str(node_path)), subnames + ":x")
	float_gadget_x.name = "FloatGadgetX"
	float_gadget_x.size_flags_horizontal = SIZE_EXPAND_FILL
	float_gadget_x.on_change_property_begin.connect(change_property_begin)
	float_gadget_x.on_change_property_end.connect(change_property_end)

	var float_gadget_y = GadgetFloat.new(NodePath("../../" + str(node_path)), subnames + ":y")
	float_gadget_y.name = "FloatGadgetY"
	float_gadget_y.size_flags_horizontal = SIZE_EXPAND_FILL
	float_gadget_y.on_change_property_begin.connect(change_property_begin)
	float_gadget_y.on_change_property_end.connect(change_property_end)

	var hbox = HBoxContainer.new()
	hbox.name = "HBoxContainer"
	hbox.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	hbox.add_child(label_x)
	hbox.add_child(float_gadget_x)
	hbox.add_child(label_y)
	hbox.add_child(float_gadget_y)

	add_child(hbox)

func populate_value(value) -> void:
	var hbox = get_controls()[0]
	var float_gadget_x = hbox.get_node("FloatGadgetX")
	var float_gadget_y = hbox.get_node("FloatGadgetY")
	float_gadget_x.populate_value(value.x)
	float_gadget_y.populate_value(value.y)

func depopulate_value() -> void:
	var hbox = get_controls()[0]
	var float_gadget_x = hbox.get_node("FloatGadgetX")
	var float_gadget_y = hbox.get_node("FloatGadgetY")
	float_gadget_x.depopulate_value()
	float_gadget_y.depopulate_value()
