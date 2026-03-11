extends Node

## Registers translations at runtime — no CSV import needed.
## Covers EN (fallback = key) and zh_CN.

func _ready() -> void:
	var t := Translation.new()
	t.locale = "zh_CN"
	var zh: Dictionary = {
		"Tutorial": "新手引导",
		"Start as Defuser": "我是拆弹者",
		"Start as Specialist": "我是拆弹专家",
		"About": "关于",
		"Go to GithubRepo": "GitHub 仓库",
		"For best game experience, do not show your monitor to the specialist":
		                            "为了最佳游戏体验，请不要让专家看到您的屏幕",
		"Continue": "继续",
	}
	for key in zh:
		t.add_message(key, zh[key])
	TranslationServer.add_translation(t)

func toggle_locale() -> void:
	if TranslationServer.get_locale().begins_with("zh"):
		TranslationServer.set_locale("en")
	else:
		TranslationServer.set_locale("zh_CN")

func get_locale() -> String:
	return TranslationServer.get_locale()
