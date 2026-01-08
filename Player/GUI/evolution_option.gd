extends PanelContainer

## Evolution Option Card - Individual evolution choice in the popup

signal selected()

@onready var icon = $VBox/Icon
@onready var name_label = $VBox/NameLabel
@onready var description_label = $VBox/DescriptionLabel
@onready var cost_label = $VBox/CostLabel
@onready var select_button = $VBox/SelectButton
@onready var locked_overlay = $LockedOverlay

var evolution_data: Dictionary = {}
var path_id: String = ""

func _ready():
	select_button.pressed.connect(_on_select_pressed)

func setup(data: Dictionary, can_afford: bool, path: String):
	evolution_data = data
	path_id = path
	
	# Set display info
	name_label.text = data.get("display_name", "Unknown")
	description_label.text = data.get("description", "")
	
	# Set cost display
	var cost_parts = []
	var gold_cost = data.get("cost_gold", 0)
	var essence_cost = data.get("cost_essence", 0)
	
	if gold_cost > 0:
		cost_parts.append(str(gold_cost) + " Gold")
	if essence_cost > 0:
		cost_parts.append(str(essence_cost) + " Essence")
	
	cost_label.text = " + ".join(cost_parts) if cost_parts.size() > 0 else "Free"
	
	# Color the cost based on affordability
	if can_afford:
		cost_label.modulate = Color(0.3, 1.0, 0.3)  # Green
		select_button.disabled = false
		if locked_overlay:
			locked_overlay.visible = false
	else:
		cost_label.modulate = Color(1.0, 0.3, 0.3)  # Red
		select_button.disabled = true
		if locked_overlay:
			locked_overlay.visible = true
	
	# Path indicator styling
	if path == "path_a":
		# Standard evolution - gold tint
		modulate = Color(1.0, 0.95, 0.85)
	else:
		# Premium evolution - purple tint
		modulate = Color(0.95, 0.9, 1.0)
	
	# Set button text
	select_button.text = "Evolve!" if can_afford else "Can't Afford"

func _on_select_pressed():
	if not select_button.disabled:
		# Play selection animation
		var tween = create_tween()
		tween.tween_property(self, "scale", Vector2(1.1, 1.1), 0.1)
		tween.tween_property(self, "scale", Vector2.ONE, 0.1)
		await tween.finished
		
		emit_signal("selected")
