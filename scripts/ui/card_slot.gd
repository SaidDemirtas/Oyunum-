class_name CardSlot
extends PanelContainer

@onready var hidden_cards_container: HBoxContainer = $VBoxContainer/HiddenCards
@onready var main_card: TextureRect = $VBoxContainer/MainCard

func _ready() -> void:
	# Oyun başladığında ekstra kartlar gizli olsun
	hidden_cards_container.visible = false
	
	# Fareyle üzerine gelme ve çıkma sinyallerini koda bağlıyoruz
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

# Fare yuvanın veya ana kartın üzerine geldiğinde (Hover)
func _on_mouse_entered() -> void:
	hidden_cards_container.visible = true

# Fare yuvadan çıktığında
func _on_mouse_exited() -> void:
	hidden_cards_container.visible = false

# Dışarıdan bu yuvaya kart verilerini yüklemek için kullanacağımız fonksiyon
func setup_slot(main_data: CardData, extra1: CardData, extra2: CardData) -> void:
	if main_data:
		main_card.texture = main_data.card_image 
	
	if extra1:
		$VBoxContainer/HiddenCards/ExtraCard1.texture = extra1.card_image
		
	if extra2:
		$VBoxContainer/HiddenCards/ExtraCard2.texture = extra2.card_image
