extends Area2D

var resource = load("res://dialogues/resume.dialogue")

func interact():
	DialogueManager.show_dialogue_balloon(resource)
