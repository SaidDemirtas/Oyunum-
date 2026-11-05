class_name StatusEffectManager
extends Node

signal effect_applied(effect_type: StatusType, stacks: int)
signal effect_removed(effect_type: StatusType)
signal damage_taken_from_effect(amount: int, effect_type: StatusType)

enum StatusType {
	POISON,     # Tur başında birikim (stack) kadar hasar verir
	BLEED,      # Oynanan her kartta hasar verir
	WEAKNESS,   # Verilen fiziksel hasarı %25 azaltır
	STRENGTH,   # Verilen fiziksel hasarı artırır
	STUN        # Turu pas geçirtir
}

# Aktif etkileri ve tur/yük sayılarını tutan sözlük { StatusType: stack_sayisi }
var active_effects: Dictionary = {}

func apply_effect(effect: StatusType, stacks: int) -> void:
	if active_effects.has(effect):
		active_effects[effect] += stacks
	else:
		active_effects[effect] = stacks
		
	effect_applied.emit(effect, active_effects[effect])

# Tur başında tetiklenen etkiler (Örn: Zehir)
func process_turn_start_effects() -> void:
	if active_effects.has(StatusType.POISON):
		var poison_dmg = active_effects[StatusType.POISON]
		damage_taken_from_effect.emit(poison_dmg, StatusType.POISON)
		_reduce_effect_stack(StatusType.POISON, 1)

# Tur sonunda azalan etkiler (Örn: Zayıflık süresi tur bitince 1 azalır)
func process_turn_end_effects() -> void:
	if active_effects.has(StatusType.WEAKNESS):
		_reduce_effect_stack(StatusType.WEAKNESS, 1)
	if active_effects.has(StatusType.STRENGTH):
		_reduce_effect_stack(StatusType.STRENGTH, 1)
	if active_effects.has(StatusType.STUN):
		_reduce_effect_stack(StatusType.STUN, 1)

# Etkinin yükünü (stack) azaltma ve bitince silme işlemi
func _reduce_effect_stack(effect: StatusType, amount: int) -> void:
	if active_effects.has(effect):
		active_effects[effect] -= amount
		if active_effects[effect] <= 0:
			active_effects.erase(effect)
			effect_removed.emit(effect)
		else:
			effect_applied.emit(effect, active_effects[effect]) # UI'ı günceller

func has_effect(effect: StatusType) -> bool:
	return active_effects.has(effect)

func clear_all_effects() -> void:
	active_effects.clear()
