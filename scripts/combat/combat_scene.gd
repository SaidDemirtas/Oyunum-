extends Control
## SAVAŞ SAHNESİ
## Görsel düzen combat_scene.tscn içinde editörde kurulur.
## Bu kod sadece sahnedeki düğümleri bulur, içlerini doldurur ve savaş mantığını yürütür.
## Eşyalar ve can PlayerData'dan (Autoload) gelir; savaş bitince can geri yazılır.
## Düğümlere "%Ad" ile erişilir: sahnede "Benzersiz Ad Olarak Eriş" işaretli olmalılar.

const INVENTORY_SCENE := "res://scenes/ui/inventory_ui.tscn"
const ENEMY_FILE := "res://data/enemies/goblin_scout.tres"

const SLOT_NAMES := {
	ItemData.EquipmentSlot.HELMET: "Kask",
	ItemData.EquipmentSlot.ARMOR: "Zırh",
	ItemData.EquipmentSlot.WEAPON: "Silah",
	ItemData.EquipmentSlot.NECKLACE: "Kolye",
	ItemData.EquipmentSlot.BOOTS: "Ayakkabı"
}

# --- Sahnedeki düğümler ---
@onready var enemy_label: Label = %EnemyLabel
@onready var intent_label: Label = %IntentLabel
@onready var log_box: RichTextLabel = %LogBox
@onready var player_label: Label = %PlayerLabel
@onready var ap_label: Label = %APLabel
@onready var end_turn_button: Button = %EndTurnButton
@onready var restart_button: Button = %RestartButton
@onready var hand_box: HBoxContainer = %HandBox

# --- Savaş sistemleri ---
var stats: PlayerStats
var equipment: EquipmentManager
var turn_manager: TurnManager
var enemy_ai: EnemyAI
var enemy_data: EnemyData

# --- Savaş durumu ---
var enemy_hp: int = 0
var enemy_block: int = 0
var battle_over: bool = false
var action_points_left: int = 0
var enemy_acting: bool = false


func _ready() -> void:
	# Editörde unutulsa bile log'un düzgün çalışması için
	log_box.bbcode_enabled = true
	log_box.scroll_following = true
	log_box.clear()

	restart_button.visible = false
	restart_button.text = "Envantere Dön"
	end_turn_button.pressed.connect(_on_end_turn_pressed)
	restart_button.pressed.connect(_on_return_pressed)

	_start_battle()


# ---------------------------------------------------------------
# SAVAŞ KURULUMU
# ---------------------------------------------------------------
func _start_battle() -> void:
	stats = PlayerStats.new()
	stats.health_depleted.connect(_on_player_died)

	equipment = EquipmentManager.new()
	equipment.player_stats = stats
	add_child(equipment)

	# Envanterde takılı eşyaları savaşa getir
	for item in PlayerData.equipped.values():
		if item != null:
			equipment.equip_item(item)
			_log("Kuşanıldı: %s (%d kart)" % [item.item_name, item.card_pool.size()])

	# Can: önceki savaştan kalan can, yoksa tam can
	var max_hp := stats.get_stat(PlayerStats.StatType.MAX_HP)
	if PlayerData.current_hp > 0:
		stats.current_hp = mini(PlayerData.current_hp, max_hp)
	else:
		stats.current_hp = max_hp

	turn_manager = TurnManager.new()
	turn_manager.equipment_manager = equipment
	turn_manager.player_stats = stats
	add_child(turn_manager)
	turn_manager.hand_updated.connect(_on_hand_updated)
	turn_manager.action_points_changed.connect(_on_ap_changed)
	turn_manager.enemy_turn_started.connect(_on_enemy_turn)
	turn_manager.turn_started.connect(_on_turn_started)

	# Düşman: .tres dosyasından yüklenir (Denetleyici'den can/hasar ayarlanabilir)
	var loaded := load(ENEMY_FILE) as EnemyData
	if loaded != null:
		enemy_data = loaded.duplicate(true)
	else:
		enemy_data = EnemyData.new()
	enemy_hp = enemy_data.max_hp
	enemy_ai = EnemyAI.new()
	add_child(enemy_ai)
	enemy_ai.intent_determined.connect(_on_intent)
	enemy_ai.action_executed.connect(_on_enemy_action)
	enemy_ai.setup(enemy_data)

	stats.stats_changed.connect(_refresh_ui)
	_refresh_ui()

	if not PlayerData.has_any_equipped_cards():
		_log("[color=red]Takılı eşyalarda hiç kart yok! Envantere dönüp eşya tak.[/color]")
		battle_over = true
		end_turn_button.visible = false
		restart_button.visible = true
		return

	turn_manager.start_combat()


func _on_return_pressed() -> void:
	get_tree().change_scene_to_file(INVENTORY_SCENE)


# ---------------------------------------------------------------
# OYUNCU TURU
# ---------------------------------------------------------------
func _on_turn_started(turn_number: int) -> void:
	_log("[b]--- Tur %d ---[/b]" % turn_number)
	enemy_acting = false
	_update_buttons()


## Eldeki kartları HandBox içine dizer.
## Şimdilik basit Button; bir sonraki adımda card_view.tscn sahnesiyle değişecek.
func _on_hand_updated(hand: Dictionary) -> void:
	for child in hand_box.get_children():
		child.queue_free()

	for slot in hand.keys():
		var card: CardData = hand[slot]
		if card == null:
			continue
		var button := Button.new()
		button.custom_minimum_size = Vector2(160, 120)
		button.text = "%s\n[%s]\n%s" % [card.card_name, SLOT_NAMES[slot], _card_summary(card)]
		button.pressed.connect(_on_card_pressed.bind(slot))
		hand_box.add_child(button)
	_update_buttons()


func _card_summary(card: CardData) -> String:
	var parts: PackedStringArray = []
	if card.base_damage > 0:
		parts.append("Hasar %d" % card.base_damage)
	if card.base_shield > 0:
		parts.append("Kalkan %d" % card.base_shield)
	if card.base_heal > 0:
		parts.append("Can +%d" % card.base_heal)
	if parts.is_empty():
		parts.append("(etkisiz)")
	return "\n".join(parts)


func _on_ap_changed(remaining: int, max_points: int) -> void:
	action_points_left = remaining
	ap_label.text = "Aksiyon: %d / %d" % [remaining, max_points]
	_update_buttons()


func _update_buttons() -> void:
	var can_play := not battle_over and not enemy_acting and action_points_left > 0
	for child in hand_box.get_children():
		if child is Button:
			child.disabled = not can_play
	end_turn_button.disabled = battle_over or enemy_acting


func _on_card_pressed(slot: int) -> void:
	if battle_over or enemy_acting:
		return
	var card: CardData = turn_manager.current_hand.get(slot)
	if card == null:
		return
	if not turn_manager.play_card(slot):
		return
	_apply_card(card)
	_refresh_ui()


func _apply_card(card: CardData) -> void:
	_log("Oynadın: %s" % card.card_name)

	if card.base_shield > 0:
		stats.add_block(card.base_shield)
		_log("  +%d kalkan." % card.base_shield)

	if card.base_heal > 0:
		stats.heal(card.base_heal)
		_log("  +%d can." % card.base_heal)

	if card.base_damage > 0:
		var damage := CombatCalculator.calculate_player_attack(card.base_damage, stats)
		_log("  Düşmana %d hasar verdin." % damage)
		if card.apply_lifesteal > 0.0:
			var stolen := roundi(damage * card.apply_lifesteal)
			if stolen > 0:
				stats.heal(stolen)
				_log("  Can çalma: +%d can." % stolen)
		_damage_enemy(damage)


func _damage_enemy(amount: int) -> void:
	var remaining := amount
	if enemy_block > 0:
		var absorbed := mini(enemy_block, remaining)
		enemy_block -= absorbed
		remaining -= absorbed
	enemy_hp = maxi(0, enemy_hp - remaining)
	if enemy_hp <= 0:
		_end_battle(true)


func _on_end_turn_pressed() -> void:
	if battle_over or enemy_acting:
		return
	turn_manager.end_player_turn()


# ---------------------------------------------------------------
# DÜŞMAN TURU
# ---------------------------------------------------------------
func _on_enemy_turn() -> void:
	if battle_over:
		return
	enemy_acting = true
	_update_buttons()
	enemy_block = 0
	_refresh_ui()
	await get_tree().create_timer(0.6).timeout
	if battle_over:
		return
	enemy_ai.execute_turn()
	if battle_over:
		return
	turn_manager.start_player_turn()


func _on_intent(intent: EnemyData.ActionIntent, value: int) -> void:
	match intent:
		EnemyData.ActionIntent.ATTACK:
			intent_label.text = "Niyet: SALDIRI (%d hasar)" % value
		EnemyData.ActionIntent.DEFEND:
			intent_label.text = "Niyet: SAVUNMA (+%d kalkan)" % value
		_:
			intent_label.text = "Niyet: ???"


func _on_enemy_action(intent: EnemyData.ActionIntent, value: int) -> void:
	match intent:
		EnemyData.ActionIntent.ATTACK:
			var damage := CombatCalculator.calculate_enemy_attack(value, stats)
			if damage < 0:
				_log("%s saldırdı ama sen kaçındın!" % enemy_data.enemy_name)
			else:
				_log("%s sana %d hasar vurdu." % [enemy_data.enemy_name, damage])
				stats.take_damage(damage)
		EnemyData.ActionIntent.DEFEND:
			enemy_block += value
			_log("%s +%d kalkan kazandı." % [enemy_data.enemy_name, value])
		_:
			_log("%s bir şey yapmadı." % enemy_data.enemy_name)
	_refresh_ui()


# ---------------------------------------------------------------
# SAVAŞ SONU
# ---------------------------------------------------------------
func _on_player_died() -> void:
	_end_battle(false)


func _end_battle(player_won: bool) -> void:
	if battle_over:
		return
	battle_over = true
	turn_manager.end_combat(player_won)
	# Canı PlayerData'ya kaydet. Test kolaylığı için yenilince bir sonraki savaşa tam canla gir.
	PlayerData.current_hp = stats.current_hp if player_won else -1
	end_turn_button.visible = false
	restart_button.visible = true
	if player_won:
		_log("[color=gold][b]*** ZAFER! Düşmanı yendin. ***[/b][/color]")
	else:
		_log("[color=red][b]*** YENİLDİN. ***[/b][/color]")
	_update_buttons()
	_refresh_ui()


# ---------------------------------------------------------------
# ARAYÜZ GÜNCELLEME
# ---------------------------------------------------------------
func _refresh_ui() -> void:
	if enemy_data == null or stats == null:
		return
	enemy_label.text = "%s   Can: %d / %d   Kalkan: %d" % [enemy_data.enemy_name, enemy_hp, enemy_data.max_hp, enemy_block]
	player_label.text = "Sen   Can: %d / %d   Kalkan: %d" % [stats.current_hp, stats.get_stat(PlayerStats.StatType.MAX_HP), stats.current_block]


func _log(text: String) -> void:
	log_box.append_text(text + "\n")
