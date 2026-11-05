class_name Chest
extends Area2D

# Sandığın içindeki eşyaları Godot editöründen sürükle-bırak ile belirlemek için
@export var loot_table: Array[ItemData] = []
var is_opened: bool = false

func _ready():
	# Farenin sandığın üzerindeki tıklamaları algılamasına izin ver
	input_pickable = true

# Tıklamayı algılayan yerleşik Area2D fonksiyonu
func _input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if not is_opened:
			open_chest()
 
func open_chest():
	is_opened = true
	
	# Sandığın açıldığını belli etmek için rengini soluklaştırıyoruz
	$Sprite2D.modulate = Color(0.3, 0.3, 0.3)
	
	print("Sandık açıldı! Çıkan Ganimetler:")
	for item in loot_table:
		print("- " + item.item_name)
