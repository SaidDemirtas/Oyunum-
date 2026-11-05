class_name CombatUI
extends Control

# Sahnedeki arayüz öğelerini koda bağlıyoruz
@onready var health_bar: ProgressBar = $PlayerStatusPanel/HealthBar
@onready var block_bar: ProgressBar = $PlayerStatusPanel/BlockBar
@onready var enemy_health_bar: ProgressBar = $EnemyStatus/EnemyHealthBar
@onready var intent_icon: TextureRect = $EnemyStatus/IntentIcon
@onready var inventory_button: Button = $InventoryButton

func _ready() -> void:
	# Oyun başlarken blok barının gizli olduğundan emin ol
	block_bar.visible = false
	
	# Envanter butonuna tıklama sinyalini koda bağlıyoruz
	inventory_button.pressed.connect(_on_inventory_button_pressed)

# Can barını güncelleyen fonksiyon
func update_health_ui(current_hp: int, max_hp: int) -> void:
	health_bar.max_value = max_hp
	health_bar.value = current_hp

# Dinamik Blok Barı Mantığı
func update_block_ui(current_block: int) -> void:
	if current_block > 0:
		block_bar.visible = true
		block_bar.value = current_block
		# Blok miktarı arttıkça barın kapasitesini de dinamik olarak genişlet
		block_bar.max_value = max(block_bar.max_value, current_block) 
	else:
		block_bar.visible = false
		block_bar.value = 0

func _on_inventory_button_pressed() -> void:
	print("Envanter ekranına geçiş tetiklendi!")
	# İleride Envanter sahnesini tamamladığımızda geçiş kodunu buraya yazacağız.


func _on_enemy_status_card_played_on_target(card: CardData, target: DropZone.ZoneType) -> void:
	pass # Replace with function body.


func _on_player_status_panel_card_played_on_target(card: CardData, target: DropZone.ZoneType) -> void:
	pass # Replace with function body.
