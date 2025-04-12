extends HBoxContainer

@onready var heart_scene = preload("res://Scenes/Hud/heart.tscn")

# Function to add a heart to the container
func add_MaxHealth():
	var heart = heart_scene.instantiate()
	add_child(heart)

# Function to set the max health by adding hearts
func set_max_health(max_hp: int):
	var hearts = get_children().size()  # Current number of hearts
	var need = max_hp - hearts  # How many more hearts are needed
	
	# Add hearts until we reach the desired max health
	for i in range(need):
		add_MaxHealth()

# Function to update the health (filled hearts vs. empty hearts)
func update(current_hp: int):
	var hearts = get_children()
	
	# Update hearts based on current HP
	for i in range(current_hp):
		if i < hearts.size():
			hearts[i].update(true)  # Set the heart to "filled" or active state
	
	# Set remaining hearts as "empty"
	for i in range(current_hp, hearts.size()):
		hearts[i].update(false)  # Set the heart to "empty" or inactive state
