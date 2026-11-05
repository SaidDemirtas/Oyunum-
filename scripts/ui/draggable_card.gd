class_name DraggableCard
extends TextureRect

var card_data: CardData

# Oyuncu karta tıklayıp sürüklemeye başladığında Godot bu fonksiyonu otomatik çalıştırır
func _get_drag_data(at_position: Vector2) -> Variant:
	if card_data == null:
		return null
		
	# Sürüklerken farenin ucunda görünecek yarı saydam kopya (Preview)
	var preview = TextureRect.new()
	preview.texture = texture
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.custom_minimum_size = size
	preview.modulate = Color(1, 1, 1, 0.7) # %70 saydamlık
	
	# Farenin kartın tam ortasından tutmasını sağlamak için taşıyıcı bir Control düğümü ekliyoruz
	var preview_control = Control.new()
	preview.position = -size / 2 
	preview_control.add_child(preview)
	
	set_drag_preview(preview_control)
	
	# Hedefe (Düşmana veya oyuncuya) fırlatılacak paketi (Dictionary) hazırlıyoruz
	return {
		"source": "combat_card",
		"card_data": card_data
	}
