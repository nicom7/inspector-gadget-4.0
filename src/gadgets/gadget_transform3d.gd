@tool
extends InspectorGadgetBase
class_name GadgetTransform3D

func _init(in_node_path: NodePath = NodePath(), in_subnames: String = ""):
	super._init(in_node_path, in_subnames)

func set_node_path(new_node_path: NodePath):
	super.set_node_path(new_node_path)

	if not has_controls():
		return

	var vbox = get_controls()[0]
	var basis_gadget = vbox.get_node("BasisGadget")
	var origin_gadget = vbox.get_node("OriginGadget")
	basis_gadget.node_path = node_path
	origin_gadget.node_path = node_path

func set_subnames(new_subnames: String):
	super.set_subnames(new_subnames)

	if not has_controls():
		return

	var vbox = get_controls()[0]
	var basis_gadget = vbox.get_node("BasisGadget")
	var origin_gadget = vbox.get_node("OriginGadget")
	basis_gadget.subnames = subnames + ":basis"
	origin_gadget.subnames = subnames + ":origin"

static func supports_type(value) -> bool:
	if value is Transform3D:
		return true
	return false

func has_controls() -> bool:
	return has_node("VBoxContainer")

func get_controls() -> Array:
	return [$VBoxContainer]

func populate_controls() -> void:
	var label_basis = Label.new()
	label_basis.text = "Basis"

	var label_origin = Label.new()
	label_origin.text = "Origin"

	var basis_gadget = GadgetBasis.new(NodePath("../../" + str(node_path)), subnames + ":basis")
	basis_gadget.name = "BasisGadget"
	basis_gadget.size_flags_horizontal = SIZE_EXPAND_FILL
	basis_gadget.on_change_property_begin.connect(change_property_begin)
	basis_gadget.on_change_property_end.connect(change_property_end)

	var origin_gadget = GadgetVector3.new(NodePath("../../" + str(node_path)), subnames + ":origin")
	origin_gadget.name = "OriginGadget"
	origin_gadget.size_flags_horizontal = SIZE_EXPAND_FILL
	origin_gadget.on_change_property_begin.connect(change_property_begin)
	origin_gadget.on_change_property_end.connect(change_property_end)

	var vbox = VBoxContainer.new()
	vbox.name = "VBoxContainer"
	vbox.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	vbox.add_child(label_basis)
	vbox.add_child(basis_gadget)
	vbox.add_child(label_origin)
	vbox.add_child(origin_gadget)

	add_child(vbox)

func populate_value(value) -> void:
	var vbox = get_controls()[0]
	var basis_gadget = vbox.get_node("BasisGadget")
	var origin_gadget = vbox.get_node("OriginGadget")
	basis_gadget.populate_value(value.basis)
	origin_gadget.populate_value(value.origin)

func depopulate_value() -> void:
	var vbox = get_controls()[0]
	var basis_gadget = vbox.get_node("BasisGadget")
	var origin_gadget = vbox.get_node("OriginGadget")
	basis_gadget.depopulate_value()
	origin_gadget.depopulate_value()
