extends Node2D

@onready var inventory_ui = $UIManager/InventoryUI

func _ready():
	# Oyun başladığında envanter kapalı olsun
	if inventory_ui != null:
		inventory_ui.hide()

func _unhandled_input(event: InputEvent) -> void:
	# Klavyeden 'I' tuşuna basıldığında (Proje Ayarları -> Girdi Haritasından "toggle_inventory" de ekleyebilirsin)
	if event is InputEventKey and event.keycode == KEY_I and event.pressed:
		if inventory_ui.visible:
			inventory_ui.hide()
		else:
			inventory_ui.show()
