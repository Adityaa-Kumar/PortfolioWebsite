extends CanvasLayer

@onready var text_label: RichTextLabel = $Panel/RichTextLabel
@onready var textbox: Panel = $Panel

@export var text_speed: float = 0.05 

var dialogue_lines: Array[String] = []
var current_line_index: int = 0
var is_dialogue_active: bool = false
var current_tween: Tween = null

func _ready():
	visible = false

func start_dialogue(lines: Array[String]):
	if is_dialogue_active:
		return
	
	dialogue_lines = lines
	current_line_index = 0
	is_dialogue_active = true
	visible = true
	
	show_text()

func show_text():
	var next_text = dialogue_lines[current_line_index]
	text_label.text = next_text
	text_label.visible_ratio = 0.0
	
	if current_tween:
		current_tween.kill()
	
	current_tween = create_tween()
	var duration = next_text.length() * text_speed
	current_tween.tween_property(text_label, "visible_ratio", 1.0, duration)

func _input(event):
	if not is_dialogue_active:
		return

	if event.is_action_pressed("ui_accept"):
		# IMPORTANT: This line prevents the Player from detecting the same key press
		get_viewport().set_input_as_handled()
		
		if text_label.visible_ratio < 1.0:
			skip_typing()
		else:
			advance_dialogue()

func skip_typing():
	if current_tween:
		current_tween.kill()
	text_label.visible_ratio = 1.0

func advance_dialogue():
	current_line_index += 1
	
	if current_line_index >= dialogue_lines.size():
		is_dialogue_active = false
		visible = false
		return
	
	show_text()

func _on_rich_text_label_meta_clicked(meta: Variant) -> void:
	OS.shell_open(meta)
