class_name CardUI extends Control

@export var name_label: Label
var card_data: CardData

## Initializes the visual representation based on the raw data.
func setup(data: CardData) -> void:
	card_data = data
	
	# Convert Enum integer to string (e.g., Suit.CUPS -> "CUPS")
	var suit_name: String = CardData.Suit.keys()[card_data.suit].capitalize()
	var rank_name: String = str(card_data.rank)
	
	# Handle face cards
	match card_data.rank:
		1: rank_name = "Ace"
		11: rank_name = "Page"
		12: rank_name = "Knight"
		13: rank_name = "Queen"
		14: rank_name = "King"
		
	name_label.text = rank_name + "\nof\n" + suit_name

## Built-in Godot function: Triggers when the user clicks and drags this Control.
func _get_drag_data(at_position: Vector2) -> Variant:
	# 1. Create a visual preview that follows the mouse
	var preview = Control.new()
	var preview_rect = ColorRect.new()
	preview_rect.size = size
	preview_rect.color = Color(0.5, 0.5, 0.5, 0.7) # Semi-transparent grey
	preview_rect.position = -size / 2 # Center the preview on the mouse
	preview.add_child(preview_rect)
	
	set_drag_preview(preview)
	
	# 2. Return the data payload we want to drop (returning self passes the whole node)
	return self
