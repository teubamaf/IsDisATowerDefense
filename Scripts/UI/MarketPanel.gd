extends PanelContainer

# Panneau de vente et achat du marché

# Taux de conversion de base
const SELL_RATES = {
	"wood": 2.0,   # 1 bois = 2 or (vente)
	"stone": 3.0,  # 1 pierre = 3 or (vente)
}

const BUY_RATES = {
	"wood": 4.0,   # 4 or = 1 bois (achat)
	"stone": 6.0,  # 6 or = 1 pierre (achat)
}

# Quantités pour transactions
var sell_amounts = {
	"wood": 10,
	"stone": 10,
}

var buy_amounts = {
	"wood": 10,
	"stone": 10,
}

var market_level: int = 1

# Références UI - Vente
@onready var wood_sell_amount_label = $VBoxContainer/WoodSellRow/AmountLabel
@onready var wood_sell_price_label = $VBoxContainer/WoodSellRow/PriceLabel
@onready var wood_sell_minus_btn = $VBoxContainer/WoodSellRow/MinusButton
@onready var wood_sell_plus_btn = $VBoxContainer/WoodSellRow/PlusButton
@onready var wood_sell_btn = $VBoxContainer/WoodSellRow/SellButton

@onready var stone_sell_amount_label = $VBoxContainer/StoneSellRow/AmountLabel
@onready var stone_sell_price_label = $VBoxContainer/StoneSellRow/PriceLabel
@onready var stone_sell_minus_btn = $VBoxContainer/StoneSellRow/MinusButton
@onready var stone_sell_plus_btn = $VBoxContainer/StoneSellRow/PlusButton
@onready var stone_sell_btn = $VBoxContainer/StoneSellRow/SellButton

# Références UI - Achat
@onready var wood_buy_amount_label = $VBoxContainer/WoodBuyRow/AmountLabel
@onready var wood_buy_price_label = $VBoxContainer/WoodBuyRow/PriceLabel
@onready var wood_buy_minus_btn = $VBoxContainer/WoodBuyRow/MinusButton
@onready var wood_buy_plus_btn = $VBoxContainer/WoodBuyRow/PlusButton
@onready var wood_buy_btn = $VBoxContainer/WoodBuyRow/BuyButton

@onready var stone_buy_amount_label = $VBoxContainer/StoneBuyRow/AmountLabel
@onready var stone_buy_price_label = $VBoxContainer/StoneBuyRow/PriceLabel
@onready var stone_buy_minus_btn = $VBoxContainer/StoneBuyRow/MinusButton
@onready var stone_buy_plus_btn = $VBoxContainer/StoneBuyRow/PlusButton
@onready var stone_buy_btn = $VBoxContainer/StoneBuyRow/BuyButton

@onready var close_btn = $VBoxContainer/CloseButton

func _ready():
	visible = false

	# Connecter les boutons de vente - Bois
	if wood_sell_minus_btn:
		wood_sell_minus_btn.pressed.connect(_on_wood_sell_minus_pressed)
	if wood_sell_plus_btn:
		wood_sell_plus_btn.pressed.connect(_on_wood_sell_plus_pressed)
	if wood_sell_btn:
		wood_sell_btn.pressed.connect(_on_sell_wood_pressed)

	# Connecter les boutons de vente - Pierre
	if stone_sell_minus_btn:
		stone_sell_minus_btn.pressed.connect(_on_stone_sell_minus_pressed)
	if stone_sell_plus_btn:
		stone_sell_plus_btn.pressed.connect(_on_stone_sell_plus_pressed)
	if stone_sell_btn:
		stone_sell_btn.pressed.connect(_on_sell_stone_pressed)

	# Connecter les boutons d'achat - Bois
	if wood_buy_minus_btn:
		wood_buy_minus_btn.pressed.connect(_on_wood_buy_minus_pressed)
	if wood_buy_plus_btn:
		wood_buy_plus_btn.pressed.connect(_on_wood_buy_plus_pressed)
	if wood_buy_btn:
		wood_buy_btn.pressed.connect(_on_buy_wood_pressed)

	# Connecter les boutons d'achat - Pierre
	if stone_buy_minus_btn:
		stone_buy_minus_btn.pressed.connect(_on_stone_buy_minus_pressed)
	if stone_buy_plus_btn:
		stone_buy_plus_btn.pressed.connect(_on_stone_buy_plus_pressed)
	if stone_buy_btn:
		stone_buy_btn.pressed.connect(_on_buy_stone_pressed)

	if close_btn:
		close_btn.pressed.connect(_on_close_pressed)

	update_display()

func show_panel(level: int = 1):
	market_level = level
	visible = true
	update_display()

func hide_panel():
	visible = false

func get_sell_rate(resource: String) -> float:
	# Le niveau du marché augmente le taux de vente de 5% par niveau
	return SELL_RATES[resource] * (1.0 + (market_level - 1) * 0.05)

func get_buy_rate(resource: String) -> float:
	# Le niveau du marché réduit le coût d'achat de 3% par niveau
	return BUY_RATES[resource] * (1.0 - (market_level - 1) * 0.03)

func update_display():
	# Affichage vente bois
	if wood_sell_amount_label:
		wood_sell_amount_label.text = str(sell_amounts["wood"])
	if wood_sell_price_label:
		var wood_sell_price = int(sell_amounts["wood"] * get_sell_rate("wood"))
		wood_sell_price_label.text = "+%d Or" % wood_sell_price

	# Affichage vente pierre
	if stone_sell_amount_label:
		stone_sell_amount_label.text = str(sell_amounts["stone"])
	if stone_sell_price_label:
		var stone_sell_price = int(sell_amounts["stone"] * get_sell_rate("stone"))
		stone_sell_price_label.text = "+%d Or" % stone_sell_price

	# Affichage achat bois
	if wood_buy_amount_label:
		wood_buy_amount_label.text = str(buy_amounts["wood"])
	if wood_buy_price_label:
		var wood_buy_price = int(buy_amounts["wood"] * get_buy_rate("wood"))
		wood_buy_price_label.text = "-%d Or" % wood_buy_price

	# Affichage achat pierre
	if stone_buy_amount_label:
		stone_buy_amount_label.text = str(buy_amounts["stone"])
	if stone_buy_price_label:
		var stone_buy_price = int(buy_amounts["stone"] * get_buy_rate("stone"))
		stone_buy_price_label.text = "-%d Or" % stone_buy_price

# --- Vente Bois ---
func _on_wood_sell_minus_pressed():
	sell_amounts["wood"] = max(1, sell_amounts["wood"] - 10)
	update_display()

func _on_wood_sell_plus_pressed():
	sell_amounts["wood"] = min(int(GameManager.wood), sell_amounts["wood"] + 10)
	update_display()

func _on_sell_wood_pressed():
	var amount = min(sell_amounts["wood"], int(GameManager.wood))
	if amount > 0:
		var gold_gained = int(amount * get_sell_rate("wood"))
		GameManager.wood -= amount
		GameManager.add_gold(gold_gained)
		GameManager.resources_changed.emit()
		update_display()

# --- Vente Pierre ---
func _on_stone_sell_minus_pressed():
	sell_amounts["stone"] = max(1, sell_amounts["stone"] - 10)
	update_display()

func _on_stone_sell_plus_pressed():
	sell_amounts["stone"] = min(int(GameManager.stone), sell_amounts["stone"] + 10)
	update_display()

func _on_sell_stone_pressed():
	var amount = min(sell_amounts["stone"], int(GameManager.stone))
	if amount > 0:
		var gold_gained = int(amount * get_sell_rate("stone"))
		GameManager.stone -= amount
		GameManager.add_gold(gold_gained)
		GameManager.resources_changed.emit()
		update_display()

# --- Achat Bois ---
func _on_wood_buy_minus_pressed():
	buy_amounts["wood"] = max(1, buy_amounts["wood"] - 10)
	update_display()

func _on_wood_buy_plus_pressed():
	buy_amounts["wood"] += 10
	update_display()

func _on_buy_wood_pressed():
	var cost = int(buy_amounts["wood"] * get_buy_rate("wood"))
	if GameManager.gold >= cost:
		GameManager.gold -= cost
		GameManager.wood += buy_amounts["wood"]
		GameManager.resources_changed.emit()
		update_display()

# --- Achat Pierre ---
func _on_stone_buy_minus_pressed():
	buy_amounts["stone"] = max(1, buy_amounts["stone"] - 10)
	update_display()

func _on_stone_buy_plus_pressed():
	buy_amounts["stone"] += 10
	update_display()

func _on_buy_stone_pressed():
	var cost = int(buy_amounts["stone"] * get_buy_rate("stone"))
	if GameManager.gold >= cost:
		GameManager.gold -= cost
		GameManager.stone += buy_amounts["stone"]
		GameManager.resources_changed.emit()
		update_display()

func _on_close_pressed():
	hide_panel()
	get_tree().call_group("building_manager", "deselect_building")
