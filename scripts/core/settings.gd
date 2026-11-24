class_name Settings
extends RefCounted
## Preferências do jogador salvas em user://settings.cfg (fora do repositório).

const PATH := "user://settings.cfg"


static func get_value(section: String, key: String, default_value: Variant) -> Variant:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		return default_value
	return cfg.get_value(section, key, default_value)


static func set_value(section: String, key: String, value: Variant) -> void:
	var cfg := ConfigFile.new()
	cfg.load(PATH)
	cfg.set_value(section, key, value)
	cfg.save(PATH)


static func tutorial_enabled() -> bool:
	return get_value("tutorial", "enabled", true)


static func set_tutorial_enabled(enabled: bool) -> void:
	set_value("tutorial", "enabled", enabled)
