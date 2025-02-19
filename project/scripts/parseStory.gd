extends Node

var mainStoryLabel
var settingsPopup
var robotoLabel = preload("res://scenes/RobotoLabel.tscn")
var buttons : Array
var data
var currentPassage = 0
var container
var linkLabels : Array
var currentLabel
var conditions : Array

onready var settingsMenu = $Popup
onready var titles = $TitlesPopup
onready var audioController = $AudioController
onready var oldStoryImage = $OldStoryImage
onready var newStoryImage = $NewStoryImage

onready var cheatsPopup = $CheatsPopup

var text_draw_speed
var image_draw_speed = 0.5
var settings_var

# Called when the node enters the scene tree for the first time.
func _ready():
	load_story("res://data/PalladaProject_eng.json")

	mainStoryLabel = get_node("ScrollContainer2/MainStoryText")
	
	container = get_node("ScrollContainer/VBoxContainer")
	process_links()
	
	settings_var = get_node("/root/SettingsVars")
	set_mainstory_text()

func load_story(filename):
	var data_file = File.new()
	if data_file.open(filename, File.READ) != OK:
		return
	var data_text = data_file.get_as_text()
	data_file.close()
	var data_parse = JSON.parse(data_text)
	if data_parse.error != OK:
		return
	data = data_parse.result

func set_mainstory_text():
	var regex = RegEx.new()
	regex.compile("<<(.*?)>>")
	var img = regex.search(data.passages[currentPassage].name)
	if img != null:
		var img_path = "res://assets/" + img.get_string().replace('<', '').replace('>', '') + ".png"
		var textureImage = Image.new()
		textureImage.load(img_path)
		var texture = ImageTexture.new()
		texture.create_from_image(textureImage)
		oldStoryImage.texture = newStoryImage.texture
		newStoryImage.modulate.a = 0
		newStoryImage.texture = load(img_path)
		#image.draw_texture(texture, Vector2(0,0))
	mainStoryLabel.text = data.passages[currentPassage].text.split("[")[0]
	mainStoryLabel.percent_visible = 0
	if mainStoryLabel.text.length() != 0:
		text_draw_speed = settings_var.draw_coef / mainStoryLabel.text.length()

func process_links():
	var passage = data.passages[currentPassage]
	linkLabels = []
	if "links" in passage:
		var links = data.passages[currentPassage].links
		for link in links:
			var should_show = true
			var should_add = false
			var str_res
			var regex = RegEx.new()
			regex.compile("{{(.*?)}}")
			var results = regex.search_all(link.name)
			if results:
				for res in results:
					str_res = res.get_string()
					var st = res.get_start()
					if st - str_res.length() > 0:
						should_add = true
					else:
						if not str_res in conditions:
							should_show = false
			if should_show:
				var textLabel = robotoLabel.instance()
				textLabel.anchor_left = 0
				textLabel.anchor_right = 1
				textLabel.connect("mouse_entered", textLabel, "_on_Mouse_entered")
				textLabel.connect("mouse_exited", textLabel, "_on_Mouse_exited")
				var linkPassage = find_by_pid(link.pid)
				if should_add:
					linkPassage.trigger = str_res
				textLabel.connect("gui_input", self, "_on_Gui", [linkPassage])
				textLabel.text = regex.sub(link.name, "", true)
				textLabel.percent_visible = 0
				container.add_child(textLabel)
				linkLabels.append(textLabel)
		currentLabel = 0
		
		

func find_by_pid(pid):
	var passages = data.passages
	for passage in passages:
		if(passage.pid == pid):
			return passage
	
	
func _on_Gui(event, linkPassage):
	if linkLabels[linkLabels.size() - 1].percent_visible != 1:
		return
	if (event is InputEventMouseButton && event.pressed && event.button_index == 1):
		if "trigger" in linkPassage:
			conditions.append(linkPassage.trigger)
		currentPassage = int(linkPassage.pid) - 1
		checkPassageForMusicChange(currentPassage)
		set_mainstory_text()
		clear_links()
		process_links()
		
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	process_draw_speed(delta)


func checkPassageForMusicChange(passage):
	if passage == 21:
		audioController.SetCurrentAudio("candy")
	if passage == 36:
		audioController.SetCurrentAudio("goodbye")
	if passage == 58 or passage == 114:
		audioController.SetCurrentAudio("enough")
	if passage == 93 or passage == 94:
		audioController.SetCurrentAudio("goodbye")
	if passage == 124 or passage == 127:
		audioController.SetCurrentAudio("headache")
		

func process_draw_speed(delta):
	if mainStoryLabel.percent_visible != 1:
		mainStoryLabel.percent_visible += text_draw_speed * delta
	if not linkLabels.empty():
		if mainStoryLabel.percent_visible == 1:
			text_draw_speed = linkLabels[currentLabel].text.length()
		if mainStoryLabel.percent_visible == 1 and linkLabels[currentLabel].percent_visible != 1:
			linkLabels[currentLabel].percent_visible += text_draw_speed * delta
		if linkLabels[currentLabel].percent_visible == 1 and currentLabel != linkLabels.size() - 1:
			currentLabel += 1
			text_draw_speed = linkLabels[currentLabel].text.length()
			
	if newStoryImage.modulate.a < 1:
		newStoryImage.modulate.a += image_draw_speed * delta
	if oldStoryImage.modulate.a > 0:
		oldStoryImage.modulate.a -= image_draw_speed * delta


func _on_PalladaProject_gui_input(event):
	if (event is InputEventMouseButton && event.pressed && event.button_index == 1):
		process_percent_visible()

func _input(event):
	if(event is InputEventKey):
		if(event.scancode == KEY_QUOTELEFT):
			cheatsPopup.popup_centered()
		
		
func process_percent_visible():
	if mainStoryLabel.percent_visible != 1:
		mainStoryLabel.percent_visible = 1
	elif not linkLabels.empty(): 
		linkLabels[currentLabel].percent_visible = 1
	
func _on_SettingsButton_pressed():
	settingsMenu.popup_centered()

func _on_Popup_speed_changed():
	var length
	if mainStoryLabel.percent_visible != 1:
		 length =mainStoryLabel.text.length()
	else: length = linkLabels[currentLabel].text.length()
	text_draw_speed = settings_var.draw_coef / length

func clear_links():
	for child in container.get_children():
			container.remove_child(child)
			child.queue_free()

func _on_Popup_language_changed():
	if(settings_var.language == "English"):
		load_story("res://data/PalladaProject_eng.json")
	else:
		load_story("res://data/PalladaProject.json")
	clear_links()
	process_links()
	set_mainstory_text()


func _on_InfoButton_pressed():
	titles.popup_centered()

func _on_Popup_sound_state_changed():
	if settings_var.disableSound == true:
		audioController.disableSound()
	else:
		audioController.enableSound()
