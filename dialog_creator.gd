extends Control

const VERSION: String = "0.1.1"

var dialog_data: Dictionary = {"conversations": {}}
var fpath: String
var t: String
var convcount: int = 0

onready var Conversations = $MarginContainer/HBoxContainer/VBoxContainer/Conversations
onready var Elements = $MarginContainer/HBoxContainer/VBoxContainer2/Elements
onready var ActionList = $MarginContainer/HBoxContainer/ScrollContainer/VBoxContainer

func _ready():
	var p = $Navbar/File.get_popup()
	var p2 = $Navbar/Help.get_popup()
	var p3 = $MarginContainer/HBoxContainer/VBoxContainer2/btnbar/add.get_popup()
	p.add_item("MENU_DIALOGNEW")
	p.add_item("MENU_DIALOGOPEN")
	p.add_separator()
	p.add_item("MENU_DIALOGSAVE")
	p.add_item("MENU_DIALOGSAVEAS")
	p.add_separator()
	p.add_item("MENU_CLOSE")
	p.connect("id_pressed", self, "on_file_item_pressed")
	p2.add_separator("Yet Another Dialog Editor")
	p2.add_separator("version " + VERSION)
	p2.add_item("MENU_HELP_ABOUT")
	p2.connect("id_pressed", self, "on_help_item_pressed")
	p3.add_item("ACTIONLIST_HEADER")
	p3.add_item("ACTIONLIST_TEXT")
	p3.add_item("ACTIONLIST_SETCHARACTERS")
	p3.add_item("ACTIONLIST_SETEXPRESSION")
	p3.connect("id_pressed", self, "on_elements_add_item_pressed")
	
	#translation stuff
	$actions/Header.title = tr("ACTIONLIST_HEADER")
	$actions/Text.title = tr("ACTIONLIST_TEXT")
	$actions/SetCharacters.title = tr("ACTIONLIST_SETCHARACTERS")
	$actions/Expression.title = tr("ACTIONLIST_SETEXPRESSION")

func on_file_item_pressed(id):
	match id:
		0:
			_on_CreateNewDialog()
		1:
			$FileDialog.popup_centered_ratio()
		3:
			_on_SaveDialog()
		4:
			$SaveDialogAs.popup_centered_ratio()
		6:
			get_tree().quit()

func on_help_item_pressed(id):
	match id:
		2:
			$About.popup_centered()

func _on_CreateNewDialog():
	print("Create new Dialog...")
	cleanup_everything()


func cleanup_everything():
	fpath = ""
	convcount = 0
	dialog_data.clear()
	Conversations.clear()
	Elements.clear()
	$Navbar/Path.text = ""
	for i in ActionList.get_child_count():
		ActionList.get_child(0).free()

func _on_FileDialog_file_selected(path):
	print("Open " + path)
	
	#cleanup
	Conversations.clear()
	Elements.clear()
	for i in ActionList.get_child_count():
		ActionList.get_child(0).free()
	
	var f = File.new()
	f.open(path, 1)
	dialog_data.clear()
	dialog_data = parse_json(f.get_as_text())
	f.close()
	if dialog_data.has("conversations"):
		$Navbar/Path.set_text(path)
		fpath = path
		for i in dialog_data.conversations.size():
			Conversations.add_item(str(dialog_data.conversations.keys()[i]))
	else:
		push_warning('Datei konnte nicht geöffnet werden, "conversations" fehlt! Möglicherweise ist diese Datei kein Dialog.')

func _on_SaveDialog():
	print("Saving dialog...")
	save_conversation()
	if fpath:
		var f = File.new()
		f.open(fpath, 2)
		f.store_string(to_json(dialog_data))
		f.close()
		print("Dialog saved.")
	else:
		print("No filepath given, opening FileDialog...")
		$SaveDialogAs.popup_centered_ratio()

func _on_SaveDialogAs_file_selected(path):
	print("Save Dialog in " + path)
	save_conversation()
	fpath = path
	var f = File.new()
	f.open(path, 2)
	f.store_string(to_json(dialog_data))
	f.close()
	$Navbar/Path.set_text(path)


func _on_Conversations_item_selected(index):
	if dialog_data.conversations.has(t):
		save_conversation()
	t = Conversations.get_item_text(index)
	replace_elements()

func _on_Conversations_item_activated(index):
	_on_Conversations_item_selected(index)

func replace_elements():
	Elements.clear()
	for i in ActionList.get_child_count():
		ActionList.get_child(0).free()
	if dialog_data.conversations:
		if dialog_data.conversations.has(""):
			dialog_data.conversations.erase("")
		for i in dialog_data.conversations[t].size():
			if dialog_data.conversations[t][i].has("type"):
				match dialog_data.conversations[t][i]["type"]:
					'header':
						Elements.add_item(dialog_data.conversations[t][i]["type"] + ": \"" + dialog_data.conversations[t][i]["value"] + "\"")
						add_header_action(dialog_data.conversations[t][i]["value"])
					'text':
						Elements.add_item(dialog_data.conversations[t][i]["type"] + ": \"" + dialog_data.conversations[t][i]["value"] + "\"")
						add_text_action(dialog_data.conversations[t][i]["value"])
					'setcharacters':
						Elements.add_item(dialog_data.conversations[t][i]["type"] + ": " + str(dialog_data.conversations[t][i]["left"]) + ", " + str(dialog_data.conversations[t][i]["right"]))
						add_setcharacters_action(dialog_data.conversations[t][i]["left"], dialog_data.conversations[t][i]["right"])
					'setexpression':
						Elements.add_item(dialog_data.conversations[t][i]["type"] + ": " + dialog_data.conversations[t][i]["character"] + ", " + dialog_data.conversations[t][i]["value"])
						add_expression_action(dialog_data.conversations[t][i]["character"], dialog_data.conversations[t][i]["value"])


func add_header_action(value: String):
	var i = $actions/Header.duplicate()
	ActionList.add_child(i)
	i.get_node('text').set_text(value)

func add_text_action(value: String):
	var i = $actions/Text.duplicate()
	ActionList.add_child(i)
	i.get_node('text').set_text(value)

func add_setcharacters_action(l: Array, r: Array):
	var i = $actions/SetCharacters.duplicate()
	ActionList.add_child(i)
	i.get_node('l/char').set_text(l[0])
	i.get_node('l/exp').set_text(l[1])
	i.get_node('r/char').set_text(r[0])
	i.get_node('r/exp').set_text(r[1])

func add_expression_action(j: String, k: String):
	var i = $actions/Expression.duplicate()
	ActionList.add_child(i)
	i.get_node('l/char').set_text(j)
	i.get_node('l/exp').set_text(k)

func _on_conversations_add_pressed():
	#save_conversation()
	convcount = convcount + 1
	if !dialog_data.has("conversations"):
		dialog_data["conversations"] = {}
	dialog_data.conversations[str(convcount)] = []
	Conversations.add_item(str(convcount))
	#Conversations.select(Conversations.get_item_count()-1)
	print(dialog_data)

func _on_conversations_del_pressed():
	var e = Conversations.get_selected_items()
	if e.size() == 1:
		e = e[0]
		var item_name = Conversations.get_item_text(e)
		print("selected item 0: " + str(e))
		print(item_name)
		print(item_name + " should be deleted, input was " + to_json(dialog_data.conversations.get(item_name)))
		dialog_data.conversations.erase(str(Conversations.get_item_text(e)))
		Conversations.remove_item(e)
		print(str(Conversations.get_item_count()-1) + " <= " + str(e) + "?")
		if Conversations.get_item_count()-1 <= e:
			print("Frickin do something, there is no selectable item!!!")
			Conversations.select(Conversations.get_item_count()-1)
			print("Selected item " + str(Conversations.get_item_count()-1))
			if Conversations.get_item_count() > 0:
				_on_Conversations_item_selected(Conversations.get_selected_items()[0])
		else:
			Conversations.select(e)
			_on_Conversations_item_selected(Conversations.get_selected_items()[0])
		if dialog_data.conversations.has(item_name):
			print("WHAT THE HELL, THE ENTRY STILL EXISTS?!? ACTIVATE TERMINATOR MODE.")
			dialog_data.erase(item_name)
			print("IT HAS BEEN DONE")

func _on_conversations_rename_pressed():
	var i = Conversations.get_selected_items()
	if i.size() > 0:
		$RenameDialog.popup_centered()
		$RenameDialog/text.text = Conversations.get_item_text(i[0])

func _on_RenameDialog_accepted(text):
	save_conversation()
	var i = Conversations.get_selected_items()
	if i.size() > 0:
		var j = Conversations.get_item_text(i[0])
		dialog_data["conversations"][text] = dialog_data["conversations"][j]
		dialog_data["conversations"].erase(j)
		Conversations.set_item_text(i[0], text)

func on_elements_add_item_pressed(id):
	if Conversations.get_item_count() == 0:
		_on_conversations_add_pressed()
	match id:
		0:
			Elements.add_item("header: \"\"")
			add_header_action("header")
		1:
			Elements.add_item("text: \"\"")
			add_text_action("text")
		2:
			Elements.add_item("setcharacters: [,], [,]")
			add_setcharacters_action(["character","expression"], ["character","expression"])
		3:
			Elements.add_item("setexpression: ,")
			add_expression_action("", "")

func _on_elements_del_pressed():
	var e = Elements.get_selected_items()
	if e:
		for i in e:
			Elements.remove_item(e[0])
			ActionList.get_child(e[0]).free()
		Elements.select(e[0])

func _on_elements_move_up_pressed():
	var e = Elements.get_selected_items()
	if e:
		Elements.move_item(e[0], e[0]-1)
		ActionList.move_child(ActionList.get_child(e[0]), e[0]-1)

func _on_elements_move_down_pressed():
	var e = Elements.get_selected_items()
	if e:
		Elements.move_item(e[0], e[0]+1)
		ActionList.move_child(ActionList.get_child(e[0]), e[0]+1)


func _on_action_text_focus_changed(idx):
	var text = ActionList.get_child(idx).get_child(1).get_text()
	print('Signal von Aktionsbox ' + str(idx))
	Elements.set_item_text(idx, "text: \"" + text + "\"")

func _on_action_header_focus_changed(idx):
	var text = ActionList.get_child(idx).get_child(1).get_text()
	print('Signal von Aktionsbox ' + str(idx))
	Elements.set_item_text(idx, "header: \"" + text + "\"")

func save_conversation():
	var build_actions: Array = []

	for i in Elements.get_item_count():
		var action = ActionList.get_child(i)
		match action.get_child(0).get_name():
			'_header':
				build_actions.push_back(str2var('{"type":"header","value":"' + action.get_child(1).get_text() + '"}'))
			'_text':
				build_actions.push_back(str2var('{"type":"text","value":"' + action.get_child(1).get_text() + '"}'))
			'_setcharacters':
				build_actions.push_back(str2var('{"type":"setcharacters","left":["' + action.get_node('l/char').get_text() + '","' + action.get_node('l/exp').get_text() + '"],"right":["' + action.get_node('r/char').get_text() + '","' + action.get_node('r/exp').get_text() + '"]}'))
			'_setexpression':
				build_actions.push_back(str2var('{"type":"setexpression","character":"' + action.get_node('l/char').get_text() + '","value":"' + action.get_node('l/exp').get_text() + '"}'))
	dialog_data["conversations"][t] = build_actions

#func save_dialog_as():
#	save_conversation()
