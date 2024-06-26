@tool
extends InspectorGadgetBase
class_name InspectorGadget

@export var property_blacklist: Array[String] = []
@export var property_whitelist: Array[String] = []
@export var property_tooltips: Dictionary = {}
@export var custom_gadget_paths: Dictionary = {}
@export var custom_gadget_metadata: Dictionary = {}
@export var container_type_hints: Dictionary = {}
@export var filter_built_in_properties: bool = true
@export var use_property_separators: bool = true

func _init(in_node_path: NodePath = NodePath(), in_subnames: String = ""):
	super._init(in_node_path, in_subnames)

func set_node_path(new_node_path: NodePath):
	super.set_node_path(new_node_path)

	if not has_controls():
		return

	var vbox = get_controls()[0]

	for child in vbox.get_children():
		child.node_path = node_path

func set_subnames(new_subnames: String):
	super.set_subnames(new_subnames)

	if not has_controls():
		return

	var vbox = get_controls()[0]

	for child in vbox.get_children():
		child.node_path = node_path

static func supports_type(value) -> bool:
	return value is Object or value is Dictionary or InspectorGadgetUtil.is_array_type(value) or value == null

func has_controls() -> bool:
	return has_node("PanelContainer")

func get_controls() -> Array:
	return [$PanelContainer/VBoxContainer]

func populate_controls() -> void:
	var vbox_container = VBoxContainer.new()
	vbox_container.name = "VBoxContainer"
	vbox_container.size_flags_horizontal = SIZE_EXPAND_FILL

	var panel_container = PanelContainer.new()
	panel_container.name = "PanelContainer"
	panel_container.size_flags_horizontal = SIZE_FILL
	panel_container.add_child(vbox_container)

	add_child(panel_container)

func populate_value(value) -> void:
	var vbox = get_controls()[0]
	if value is Object:
		var property_list = value.get_property_list()
		for property in property_list:
			if property['name'] in property_blacklist:
				continue

			if not property_whitelist.is_empty() and property['name'] not in property_whitelist:
				continue

			var is_editor_variable = PROPERTY_USAGE_EDITOR & property['usage'] != 0

			if not is_editor_variable:
				continue

			var is_script_variable = PROPERTY_USAGE_SCRIPT_VARIABLE & property['usage'] != 0

			if filter_built_in_properties and not is_script_variable:
				continue

			var type: = property['type'] as Variant.Type
			var is_enum_variable = (PROPERTY_HINT_ENUM == property['hint'])
			var has_range: bool
			var hint_string: String = property['hint_string']

			if (type == TYPE_PACKED_BYTE_ARRAY
			or type == TYPE_PACKED_INT32_ARRAY
			or type == TYPE_PACKED_INT64_ARRAY
			or type == TYPE_PACKED_FLOAT32_ARRAY
			or type == TYPE_PACKED_FLOAT64_ARRAY):
				var hint_value: = hint_string.get_slice('/', 1)
				if hint_value.begins_with(str(PROPERTY_HINT_RANGE)):
					has_range = true
					var prefix: StringName = "%d:" % PROPERTY_HINT_RANGE
					hint_string = hint_value.right(-prefix.length())
			elif (PROPERTY_HINT_RANGE == property['hint']):
				has_range = true

			var property_name: String = property['name']

			if typeof(value[property_name]) != TYPE_BOOL:
				# Do not add separate label for bool values; name will be displayed next to checkbox
				var label = Label.new()
				label.text = property_name.capitalize()
				vbox.add_child(label)

			var gadget: InspectorGadgetBase
			if is_enum_variable and not hint_string.is_empty():
				gadget = GadgetEnum.new()
				var idx: = 0
				var enum_values: PackedStringArray = hint_string.split(',')
				for s in enum_values:
					# Hint string can be one of two forms, e.g:
					#	"enum_1,enum_2,enum_3" or
					#	"enum_1:1,enum_2:2,enum_3:4"
					# So we need to split with ':' to get the effective enum values, or consider 0, 1, 2... if no ':'
					var kvp: PackedStringArray = s.split(':')
					gadget.enum_data[kvp[0]] = kvp[1].to_int() if kvp.size() > 1 else idx
					idx += 1
			else:
				gadget = get_gadget_for_value(value[property_name], subnames + ":" + property_name, property_name)

			if gadget:
				gadget.size_flags_horizontal = SIZE_EXPAND_FILL
				gadget.node_path = NodePath("../../../" + str(node_path))
				if subnames != "":
					gadget.subnames = subnames + ":" + property_name
				else:
					gadget.subnames = ":" + property_name
				gadget.on_change_property_begin.connect(change_property_begin)
				gadget.on_change_property_end.connect(change_property_end)
				gadget.on_gadget_event.connect(gadget_event)

				propagate_properties(gadget)

				if has_range:
					gadget.range_hints = hint_string

				if property_tooltips.has(property_name):
					gadget.tooltip_text = (property_tooltips[property_name] as String).c_unescape()

				vbox.add_child(gadget)

				if use_property_separators:
					add_horizontal_separator(vbox)

	elif InspectorGadgetUtil.is_array_type(value):
		for i in range(0, value.size()):
			var label = Label.new()
			label.text = str(i)

			var hbox := HBoxContainer.new()
			hbox.size_flags_horizontal = SIZE_EXPAND_FILL
			hbox.add_child(label)

			var gadget: InspectorGadgetBase = get_gadget_for_value(value[i], subnames + ":*")
			if gadget:
				gadget.size_flags_horizontal = SIZE_EXPAND_FILL
				gadget.node_path = NodePath("../../../../" + str(node_path))
				gadget.subnames = subnames + ":" + str(i)
				gadget.on_change_property_begin.connect(change_property_begin)
				gadget.on_change_property_end.connect(change_property_end)
				gadget.on_gadget_event.connect(gadget_event)

				gadget.range_hints = range_hints

				propagate_properties(gadget)

				hbox.add_child(gadget)

			if editable:
				var delete_button := Button.new()
				delete_button.text = "X"
				delete_button.pressed.connect(func(): remove_array_element(value, i))
				hbox.add_child(delete_button)

			vbox.add_child(hbox)

			if use_property_separators and i < value.size() - 1:
				add_horizontal_separator(vbox)

		if editable:
			if use_property_separators:
				add_horizontal_separator(vbox)

			var new_button = Button.new()
			new_button.text = "+ New"

			var type_hint = null
			for k in container_type_hints.keys():
				# RegEx support for type hints. For example, :array1:[0-9]+:array2 will set the
				# array2 type hint for any array1 element
				var re: = RegEx.new()
				var error: = re.compile("^" + k + "$")
				if error != Error.OK: continue
				var re_match = re.search(subnames)
				if re_match and not re_match.get_string().is_empty():
					type_hint = container_type_hints[k]
					break

			if type_hint == null:
				if value is PackedByteArray:
					type_hint = 0
				elif value is PackedInt32Array:
					type_hint = 0
				elif value is PackedFloat32Array:
					type_hint = 0.0
				elif value is PackedStringArray:
					type_hint = ""
				elif value is PackedVector2Array:
					type_hint = Vector2.ZERO
				elif value is PackedVector3Array:
					type_hint = Vector3.ZERO
				elif value is PackedColorArray:
					type_hint = Color.WHITE

			new_button.pressed.connect(func(): add_array_element(value, type_hint))
			vbox.add_child(new_button)

	elif value is Dictionary:
		var keys = value.keys()
		var vals = value.values()
		for i in range(0, keys.size()):
			var key = keys[i]
			var val = vals[i]

			var key_gadget: InspectorGadgetBase = get_gadget_for_value(key, subnames + ":[keys]")
			if key_gadget:
				key_gadget.size_flags_horizontal = SIZE_EXPAND_FILL
				key_gadget.node_path = NodePath("../../../../../" + str(node_path))
				key_gadget.subnames = subnames + ":[keys]:" + str(i)
				key_gadget.on_change_property_begin.connect(change_property_begin)
				key_gadget.on_change_property_end.connect(change_property_end)
				key_gadget.on_gadget_event.connect(gadget_event)

				propagate_properties(key_gadget)

			var value_gadget: InspectorGadgetBase = get_gadget_for_value(val, subnames + ":[values]")
			if value_gadget:
				value_gadget.size_flags_horizontal = SIZE_EXPAND_FILL
				value_gadget.node_path = NodePath("../../../../../" + str(node_path))
				value_gadget.subnames = subnames + ":[values]:" + str(i)
				value_gadget.on_change_property_begin.connect(change_property_begin)
				value_gadget.on_change_property_end.connect(change_property_end)
				value_gadget.on_gadget_event.connect(gadget_event)

				propagate_properties(value_gadget)

			var hbox = HBoxContainer.new()
			hbox.size_flags_horizontal = SIZE_EXPAND_FILL
			hbox.size_flags_vertical = SIZE_EXPAND_FILL
			hbox.add_child(key_gadget)
			hbox.add_child(value_gadget)

			if editable:
				var delete_button := Button.new()
				delete_button.text = "X"
				delete_button.pressed.connect(func(): remove_dictionary_element(value, key))
				hbox.add_child(delete_button)

			var panel_container = PanelContainer.new()
			panel_container.add_child(hbox)

			vbox.add_child(panel_container)

		if editable:
			if use_property_separators:
				add_horizontal_separator(vbox)

			var new_button = Button.new()
			new_button.text = "+ New"

			var key_type_hint = null
			if subnames + ":[keys]" in container_type_hints:
				key_type_hint = container_type_hints[subnames + ":[keys]"]

			var value_type_hint = null
			if subnames + ":[values]" in container_type_hints:
				value_type_hint = container_type_hints[subnames + ":[values]"]

			new_button.pressed.connect(func(): add_dictionary_element(value, key_type_hint, value_type_hint))
			vbox.add_child(new_button)

func add_array_element(array, type_hint) -> void:
	var _node = _node_ref.get_ref()
	if not _node:
		return

	change_property_begin(_node, subnames)
	var value = null
	if type_hint is Script:
		value = type_hint.new()
	else:
		value = type_hint

	array.append(value)
	if not InspectorGadgetUtil.is_by_ref_type(array):
		set_node_value(array)

	change_property_end(_node, subnames)

func remove_array_element(array, index: int) -> void:
	var _node = _node_ref.get_ref()
	if not _node:
		return

	change_property_begin(_node, subnames)

	array.remove_at(index)
	if not InspectorGadgetUtil.is_by_ref_type(array):
		set_node_value(array)

	change_property_end(_node, subnames)

func add_dictionary_element(dict: Dictionary, key_type_hint, value_type_hint) -> void:
	var _node = _node_ref.get_ref()
	if not _node:
		return

	change_property_begin(_node, subnames)
	var key = null
	if key_type_hint is Script:
		key = key_type_hint.new()
	else:
		key = key_type_hint

	var value = null
	if value_type_hint is Script:
		value = value_type_hint.new()
	else:
		value = value_type_hint

	dict[key] = value
	change_property_end(_node, subnames)

func remove_dictionary_element(dict: Dictionary, key) -> void:
	var _node = _node_ref.get_ref()
	if not _node:
		return

	change_property_begin(_node, subnames)
	dict.erase(key)
	change_property_end(_node, subnames)

func depopulate_value() -> void:
	var vbox = get_controls()[0]
	for child in vbox.get_children():
		vbox.remove_child(child)
		child.queue_free()

func get_gadget_for_value(value, subnames: String, property_name: String = "") -> InspectorGadgetBase:
	return get_gadget_for_type(typeof(value), subnames, property_name)

func get_gadget_for_type(type, subnames: String, property_name: String = "") -> InspectorGadgetBase:
	var gadget: InspectorGadgetBase = null

	if subnames in custom_gadget_paths:
		gadget = custom_gadget_paths[subnames].new() as InspectorGadgetBase
	else:
		match type:
			TYPE_NIL:
				pass
			TYPE_BOOL:
				gadget = GadgetBool.new()
			TYPE_INT:
				gadget = GadgetInt.new()
			TYPE_FLOAT:
				gadget = GadgetFloat.new()
			TYPE_STRING:
				gadget = GadgetStringEdit.new()
			TYPE_VECTOR2:
				gadget = GadgetVector2.new()
			TYPE_RECT2:
				gadget = GadgetRect2.new()
			TYPE_VECTOR3:
				gadget = GadgetVector3.new()
			TYPE_TRANSFORM2D:
				gadget = GadgetTransform2D.new()
			TYPE_PLANE:
				gadget = GadgetPlane.new()
			TYPE_QUATERNION:
				gadget = GadgetQuaternion.new()
			TYPE_AABB:
				gadget = GadgetAABB.new()
			TYPE_BASIS:
				gadget = GadgetBasis.new()
			TYPE_TRANSFORM3D:
				gadget = GadgetTransform3D.new()
			TYPE_COLOR:
				gadget = GadgetColor.new()
			TYPE_RID:
				gadget = GadgetRID.new()
			TYPE_OBJECT:
				gadget = get_script().new()
			TYPE_DICTIONARY:
				gadget = get_script().new()
			TYPE_ARRAY:
				gadget = get_script().new()
			TYPE_PACKED_BYTE_ARRAY:
				gadget = get_script().new()
			TYPE_PACKED_INT32_ARRAY:
				gadget = get_script().new()
			TYPE_PACKED_FLOAT32_ARRAY:
				gadget = get_script().new()
			TYPE_PACKED_STRING_ARRAY:
				gadget = get_script().new()
			TYPE_PACKED_VECTOR2_ARRAY:
				gadget = get_script().new()
			TYPE_PACKED_VECTOR3_ARRAY:
				gadget = get_script().new()
			TYPE_PACKED_COLOR_ARRAY:
				gadget = get_script().new()

	if gadget:
		gadget.property_name = property_name.capitalize()

	return gadget

func add_horizontal_separator(parent: Control) -> void:
	var separator = HSeparator.new()
	separator.size_flags_horizontal = SIZE_EXPAND_FILL
	parent.add_child(separator)

func propagate_properties(target_gadget) -> void:
	if 'custom_gadget_paths' in target_gadget:
		target_gadget.custom_gadget_paths = custom_gadget_paths

	if 'custom_gadget_metadata' in target_gadget:
		target_gadget.custom_gadget_metadata = custom_gadget_metadata

	if 'container_type_hints' in target_gadget:
		target_gadget.container_type_hints = container_type_hints

	if 'filter_built_in_properties' in target_gadget:
		target_gadget.filter_built_in_properties = filter_built_in_properties

	if 'use_property_separators' in target_gadget:
		target_gadget.use_property_separators = use_property_separators
