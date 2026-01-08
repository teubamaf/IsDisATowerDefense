extends PanelContainer

# Panneau de vente du marché

# Taux de conversion de base (ressource -> or)
const BASE_RATES = {
	"wood": 2.0,   # 1 bois = 2 or
	"stone": 3.0,  # 1 pierre = 3 or
}

# Quantités à vendre
var sell_amounts = {
	"wood": 10,
	"stone": 10,
}

var market_level: int = 1

# Références UI
@onready var wood_amount_label = $VBoxContainer/WoodRow/AmountLabel
@onready var wood_price_label = $VBoxContainer/WoodRow/PriceLabel
@onready var wood_minus_btn = $VBoxContainer/WoodRow/MinusButton
@onready var wood_plus_btn = $VBoxContainer/WoodRow/PlusButton
@onready var wood_sell_btn = $VBoxContainer/WoodRow/SellButton

@onready var stone_amount_label = $VBoxContainer/StoneRow/AmountLabel
@onready var stone_price_label = $VBoxContainer/StoneRow/PriceLabel
@onready var stone_minus_btn = $VBoxContainer/StoneRow/MinusButton
@onready var stone_plus_btn = $VBoxContainer/StoneRow/PlusButton
@onready var stone_sell_btn = $VBoxContainer/StoneRow/SellButton

@onready var close_btn = $VBoxContainer/CloseButton

func _ready():
	visible = false

	# Connecter les boutons
	if wood_minus_btn:
		wood_minus_btn.pressed.connect(_on_wood_minus_pressed)
	if wood_plus_btn:
		wood_plus_btn.pressed.connect(_on_wood_plus_pressed)
	if wood_sell_btn:
		wood_sell_btn.pressed.connect(_on_sell_wood_pressed)

	if stone_minus_btn:
		stone_minus_btn.pressed.connect(_on_stone_minus_pressed)
	if stone_plus_btn:
		stone_plus_btn.pressed.connect(_on_stone_plus_pressed)
	if stone_sell_btn:
		stone_sell_btn.pressed.connect(_on_sell_stone_pressed)

	if close_btn:
		close_btn.pressed.connect(_on_close_pressed)

	update_display()

func show_panel(level: int = 1):
	market_level = level
	visible = true
	update_display()

func hide_panel():
	visible = false

func get_rate(resource: String) -> float:
	# Le niveau du marché augmente le taux de 5% par niveau
	return BASE_RATES[resource] * (1.0 + (market_level - 1) * 0.05)

func update_display():
	if wood_amount_label:
		wood_amount_label.text = str(sell_amounts["wood"])
	if wood_price_label:
		var wood_price = int(sell_amounts["wood"] * get_rate("wood"))
		wood_price_label.text = "%d Or" % wood_price

	if stone_amount_label:
		stone_amount_label.text = str(sell_amounts["stone"])
	if stone_price_label:
		var stone_price = int(sell_amounts["stone"] * get_rate("stone"))
		stone_price_label.text = "%d Or" % stone_price

func _on_wood_minus_pressed():
	sell_amounts["wood"] = max(1, sell_amounts["wood"] - 10)
	update_display()

func _on_wood_plus_pressed():
	sell_amounts["wood"] = min(int(GameManager.wood), sell_amounts["wood"] + 10)
	update_display()

func _on_stone_minus_pressed():
	sell_amounts["stone"] = max(1, sell_amounts["stone"] - 10)
	update_display()

func _on_stone_plus_pressed():
	sell_amounts["stone"] = min(int(GameManager.stone), sell_amounts["stone"] + 10)
	update_display()

func _on_sell_wood_pressed():
	var amount = min(sell_amounts["wood"], int(GameManager.wood))
	if amount > 0:
		var gold_gained = int(amount * get_rate("wood"))
		GameManager.wood -= amount
		GameManager.add_gold(gold_gained)
		GameManager.resources_changed.emit()
		update_display()

func _on_sell_stone_pressed():
	var amount = min(sell_amounts["stone"], int(GameManager.stone))
	if amount > 0:
		var gold_gained = int(amount * get_rate("stone"))
		GameManager.stone -= amount
		GameManager.add_gold(gold_gained)
		GameManager.resources_changed.emit()
		update_display()

func _on_close_pressed():
	hide_panel()
	get_tree().call_group("building_manager", "deselect_building")
