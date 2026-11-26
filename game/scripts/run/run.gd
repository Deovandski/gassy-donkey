extends Node2D
## One run through a stage: the donkey runs on its own and speeds up every 200 m (2016 sketch: "speed
## x1.2 every 200 m"); the player jumps, double jumps up a level, swipes down a level, farts and headbutts.
##
## Coordinates: x in pixels from the stage start (StageGenerator.PX_PER_M per metre), y from the top of
## the screen. The world node moves left as the donkey runs; the donkey stays at DONKEY_SCREEN_X.

const RunHud := preload("res://scripts/run/run_hud.gd")
const DONKEY_SCREEN_X := 300.0
const GRAVITY := 2200.0
const JUMP_HEIGHT := 165.0
const HALF_W := 42.0
const BODY_H := 92.0
const GAS_MAX := 100.0
const FART_COST := 34.0
const INVULNERABLE := 1.3
const COYOTE := 0.09

var stage: Dictionary
var world_data: Dictionary
var layout: Dictionary
var stats: Dictionary
var prog: Dictionary
var speed_data: Dictionary

var world: Node2D
var visuals := RunVisuals.new()
var donkey: Donkey
var hud

var scroll := 0.0
var x := 0.0
var y := StageGenerator.FLOOR_Y
var vy := 0.0
var surface := 0  # tier the donkey stands on, or -1 in the air
var jumps := 0
var coyote := 0.0
var drop_tier := -1
var jumped_from_tier := -1
var jump_time := 0.0
var hearts := 3
var max_hearts := 3
var gas := 0.0
var invulnerable := 0.0
var boost := 0.0
var boost_factor := 1.0
var stumble := 0.0
var headbutt := 0.0
var headbutt_cooldown := 0.0
var headbutt_done := false
var in_water := false
var current_speed := 0.0
var time := 0.0

var things: Array = []
var gas_nodes: Array = []
var chasers: Array = []
var bullets: Array = []
var _tigers_left: Array = []
var _mosquitoes_left: Array = []

# Results
var gas_got := 0
var enemies := 0
var was_hit := false
var xp_run := 0
var over := false
var finished := false
var achievements_before: Dictionary
## Developer option (--param=autoplay:1): a simple bot plays, to check stages can be finished.
var autoplay := false


func _ready() -> void:
	var stage_id: String = Router.params.get("stage", "amazon_1")
	stage = GameData.stage(stage_id)
	world_data = GameData.world_of_stage(stage_id)
	layout = StageGenerator.generate(stage, GameData.worlds.get("things", {}))
	stats = SaveManager.stats()
	prog = GameData.progression
	speed_data = GameData.worlds["speed"]
	max_hearts = Progression.hearts(stats, prog)
	hearts = max_hearts
	achievements_before = SaveManager.data["achievements"].duplicate()
	autoplay = Router.params.has("autoplay")
	if autoplay:
		SaveManager.autosave = false  # the bot never touches the real save
	if Router.params.has("stats"):
		# --param=stats:2,1,3,1 (health, fart, jump, headbutt) for the bot
		var ranks: PackedStringArray = str(Router.params["stats"]).split(",")
		stats = {"health": int(ranks[0]), "fart": int(ranks[1]), "jump": int(ranks[2]), "headbutt": int(ranks[3])}
		max_hearts = Progression.hearts(stats, prog)
		hearts = max_hearts
	_tigers_left = layout["tigers"].duplicate()
	_mosquitoes_left = layout["mosquitoes"].duplicate()

	visuals.build_background(self, world_data)
	world = Node2D.new()
	world.name = "World"
	add_child(world)
	visuals.build_world(world, layout, world_data)
	for t in layout["things"]:
		var thing := Thing.new()
		thing.setup(t["type"], GameData.thing(t["type"]), t["x"], t["tier"])
		thing.shot.connect(_on_shot)
		world.add_child(thing)
		things.append(thing)
	var gas_tex: Texture2D = load("res://art/new/%s.png" % world_data["gas_item"])
	for g in layout["gas"]:
		var s := Sprite2D.new()
		s.texture = gas_tex
		s.position = Vector2(g["x"], g["y"])
		world.add_child(s)
		gas_nodes.append(s)
	donkey = Donkey.new()
	world.add_child(donkey)

	hud = RunHud.new()
	hud.run = self
	add_child(hud)
	Audio.music(GameData.stage_music(stage["id"]))
	hud.toast("%s · %s" % [world_data["name"], stage["name"]], 2.5)


# ------------------------------------------------------------------------------------------- per frame

func metres() -> float:
	return maxf(0, x) / StageGenerator.PX_PER_M


func base_speed() -> float:
	return float(speed_data["base_px_s"]) * Progression.speed_factor(metres(), speed_data)


func gravity() -> float:
	return GRAVITY * float(stage.get("gravity", 1.0))


func jump_speed() -> float:
	return sqrt(2.0 * GRAVITY * JUMP_HEIGHT) * Progression.jump_factor(stats, prog)


func _physics_process(delta: float) -> void:
	if over:
		return
	time += delta
	invulnerable = maxf(0, invulnerable - delta)
	boost = maxf(0, boost - delta)
	stumble = maxf(0, stumble - delta)
	headbutt = maxf(0, headbutt - delta)
	headbutt_cooldown = maxf(0, headbutt_cooldown - delta)
	coyote = maxf(0, coyote - delta)
	_read_keys()
	if autoplay:
		_autoplay()

	var speed := base_speed()
	if boost > 0:
		speed *= boost_factor
	if in_water and surface == 0:
		speed *= 0.55
	if stumble > 0:
		speed *= 0.45
	current_speed = speed
	var old_x := x
	x += speed * delta
	scroll = x - DONKEY_SCREEN_X
	_move_vertically(delta)

	_events(old_x)
	_collide()
	for t in things:
		if is_instance_valid(t):
			t.act(delta, x)
	_move_bullets(delta)
	var info := {"x": x, "y": y, "speed": current_speed, "on_floor": surface == 0}
	chasers = chasers.filter(func(c): return is_instance_valid(c))
	things = things.filter(func(t): return is_instance_valid(t))
	for c in chasers:
		c.step(delta, base_speed(), info)

	# The world follows the donkey; it also rises when the donkey climbs high.
	var target_y := clampf(230.0 - y, 0.0, 260.0)
	world.position = Vector2(-scroll, lerpf(world.position.y, target_y, 5 * delta))
	visuals.scroll_background(scroll, get_viewport_rect().size.x)
	donkey.position = Vector2(x, y)
	donkey.show_state(surface >= 0, headbutt > 0, 0.8 + 0.5 * Progression.speed_factor(metres(), speed_data))
	donkey.blink(invulnerable > 0, time)
	hud.refresh()

	if x >= layout["length"]:
		_end(true)


func _move_vertically(delta: float) -> void:
	var prev_y := y
	if surface >= 0:
		var support := _support_at(surface)
		if support < 0:
			surface = -1  # ran off the end of a platform
			coyote = COYOTE
			vy = 0
		else:
			y = support
			if surface == 0:
				var f := StageGenerator.floor_at(layout, x)
				if f["water"] and not in_water:
					Audio.play("splash")
					hud.float_text("Splash! Slow going", Vector2(x, y - 120), Color(0.7, 0.9, 1))
				in_water = f["water"]
			return
	vy += gravity() * delta
	y += vy * delta
	if vy < 0:
		return
	# Landing: platforms from above, then the floor.
	for tier in [2, 1]:
		var top: float = StageGenerator.TIER_Y[tier]
		if tier == drop_tier:
			if y > top + 30:
				drop_tier = -1
			continue
		if prev_y <= top + 2 and y >= top and _on_platform(tier, x):
			_land(tier, top)
			return
	var f := StageGenerator.floor_at(layout, x)
	if y >= f["y"]:
		drop_tier = -1
		_land(0, f["y"])


func _land(tier: int, top: float) -> void:
	y = top
	vy = 0
	surface = tier
	jumps = 0
	if tier > 0 or not StageGenerator.floor_at(layout, x)["water"]:
		Audio.play("land", 1.0, -6)


## The y the donkey stands on at its tier, or -1 when there's nothing there.
func _support_at(tier: int) -> float:
	if tier == 0:
		return StageGenerator.floor_at(layout, x)["y"]
	return StageGenerator.TIER_Y[tier] if _on_platform(tier, x) else -1.0


func _on_platform(tier: int, at_x: float) -> bool:
	for p in layout["platforms"]:
		if int(p["tier"]) == tier and at_x + HALF_W * 0.6 > p["x0"] and at_x - HALF_W * 0.6 < p["x1"]:
			return true
	return false


# ------------------------------------------------------------------------------------------- actions

func _read_keys() -> void:
	if Input.is_action_just_pressed("jump"):
		do_jump()
	if Input.is_action_just_pressed("drop"):
		do_drop()
	if Input.is_action_just_pressed("fart"):
		do_fart()
	if Input.is_action_just_pressed("headbutt"):
		do_headbutt()


func do_jump() -> void:
	if over:
		return
	if surface >= 0 or coyote > 0:
		jumped_from_tier = surface if surface >= 0 else -1
		jump_time = time
		surface = -1
		coyote = 0
		vy = -jump_speed()
		jumps = 1
		in_water = false
		Audio.play("jump")
	elif jumps < 2:
		vy = -jump_speed() * 0.97
		jumps = 2
		Audio.play("double_jump")


## Swipe down / S / Down: drop through the platform you stand on; in the air, fall fast.
## A swipe that starts with a tap jumps first, so a drop right after a jump from a platform still drops.
func do_drop() -> void:
	if over:
		return
	if surface > 0:
		_drop_through(surface)
	elif surface < 0 and jumped_from_tier > 0 and time - jump_time < 0.3:
		_drop_through(jumped_from_tier)
	elif surface < 0:
		vy = maxf(vy, 950.0)


func _drop_through(tier: int) -> void:
	drop_tier = tier
	surface = -1
	y = StageGenerator.TIER_Y[tier] + 4
	vy = 200.0
	jumps = 1
	jumped_from_tier = -1


func do_fart() -> void:
	if over:
		return
	var super_fart := gas >= GAS_MAX - 0.5
	if gas < FART_COST and not super_fart:
		Audio.play("fart_fizzle")
		hud.float_text("No gas! Eat some %s" % world_data["gas_item_name"], Vector2(x, y - 140), UiTheme.PEACH)
		return
	SaveManager.count("farts")
	var radius := Progression.fart_radius(stats, prog)
	if super_fart:
		gas = 0
		SaveManager.count("super_farts")
		Audio.play("super_fart")
		boost = 1.6
		boost_factor = Progression.fart_boost(stats, prog) + 0.3
		invulnerable = maxf(invulnerable, 2.0)
		radius *= 2.0
		hud.float_text("SUPER FART!", Vector2(x, y - 160), UiTheme.ORANGE, 40)
	else:
		gas -= FART_COST
		Audio.fart()
		boost = 0.6 + 0.1 * (int(stats["fart"]) - 1)
		boost_factor = Progression.fart_boost(stats, prog)
	if surface < 0:
		vy = minf(vy, -420.0)  # a fart in the air gives a little lift
	_puff(super_fart)
	for c in chasers:
		if not is_instance_valid(c) or c.state == Chaser.State.LEAVING:
			continue
		if absf(c.position.x - x) > radius:
			continue
		if c.kind == "mosquito":
			c.leave(Vector2(-1, -1))
			SaveManager.count("mosquitoes")
			_reward(int(prog["xp"]["enemy"]), "Mosquito gone!", c.position)
		elif c.state == Chaser.State.CHASING:
			if super_fart or Progression.scares_tiger(stats):
				c.leave(Vector2(-1, 0))
				SaveManager.count("tigers")
				_reward(int(prog["xp"]["tiger_scared"]), "Tiger scared away!", c.position)
			else:
				hud.float_text("Not stinky enough! Farting power 2 scares tigers", Vector2(x, y - 150), UiTheme.PEACH)


func do_headbutt() -> void:
	if over or headbutt_cooldown > 0 or surface < 0:
		return
	headbutt = 0.32
	headbutt_cooldown = 0.6
	headbutt_done = false
	Audio.play("headbutt")


func _puff(big: bool) -> void:
	var p := Sprite2D.new()
	p.texture = load("res://art/new/%s.png" % ("super_puff" if big else "fart_puff_%d" % randi_range(1, 3)))
	p.position = Vector2(x - 70, y - 55)
	p.scale = Vector2.ONE * (1.6 if big else 0.9)
	world.add_child(p)
	var tw := p.create_tween().set_parallel()
	tw.tween_property(p, "position", p.position + Vector2(-160, -40), 1.0)
	tw.tween_property(p, "scale", p.scale * 1.8, 1.0)
	tw.tween_property(p, "modulate:a", 0.0, 1.0)
	tw.chain().tween_callback(p.queue_free)


# ------------------------------------------------------------------------------------------- the world

func donkey_rect() -> Rect2:
	return Rect2(x - HALF_W, y - BODY_H, HALF_W * 2, BODY_H)


func _events(old_x: float) -> void:
	for t in _tigers_left.duplicate():
		if x + 1300 > t:
			_tigers_left.erase(t)
			var tiger := Chaser.new()
			tiger.setup("tiger")
			tiger.position = Vector2(t, StageGenerator.FLOOR_Y)
			tiger.bite.connect(_on_bite)
			world.add_child(tiger)
			chasers.append(tiger)
	for m in _mosquitoes_left.duplicate():
		if x > m:
			_mosquitoes_left.erase(m)
			var mosquito := Chaser.new()
			mosquito.setup("mosquito")
			mosquito.position = Vector2(x - 400, y - 80)
			mosquito.behind = 400
			mosquito.bite.connect(_on_bite)
			world.add_child(mosquito)
			chasers.append(mosquito)
			Audio.play("buzz")
			hud.float_text("A mosquito! Fart it away", Vector2(x, y - 170), UiTheme.PEACH)
	# Distance marks every 200 m, when the speed goes up.
	if floori(metres() / float(speed_data["step_every_m"])) > floori((old_x / StageGenerator.PX_PER_M) / float(speed_data["step_every_m"])):
		if Progression.speed_factor(metres(), speed_data) < float(speed_data["max_factor"]) + 0.001:
			hud.toast("Speed %d!" % Progression.speed_level(metres(), speed_data), 1.2)


func _collide() -> void:
	var me := donkey_rect()
	# Gas items
	for g in gas_nodes.duplicate():
		if absf(g.position.x - x) < 55 and absf(g.position.y - (y - BODY_H / 2)) < 75:
			gas_nodes.erase(g)
			g.queue_free()
			gas = minf(GAS_MAX, gas + 20.0)
			gas_got += 1
			SaveManager.count("corn")
			xp_run += int(prog["xp"]["corn"])
			Audio.play(world_data["gas_item"], randf_range(0.95, 1.1))
			if gas_got == layout["gas"].size():
				Audio.play("all_corn")
				hud.toast("All the %s! +%d XP" % [world_data["gas_item_name"], int(prog["xp"]["all_corn"])], 2.0)
				xp_run += int(prog["xp"]["all_corn"])
	# Headbutt reach
	if headbutt > 0 and not headbutt_done:
		var reach := Rect2(x + HALF_W - 10, y - BODY_H, Progression.headbutt_reach(stats, prog), BODY_H)
		for t in things:
			if is_instance_valid(t) and t.alive and t.rect().intersects(reach):
				headbutt_done = true
				_headbutt_hit(t)
				break
		for c in chasers:
			if is_instance_valid(c) and c.kind == "tiger" and c.state == Chaser.State.WAITING and c.rect().intersects(reach):
				headbutt_done = true
				_bonk("Tigers don't mind headbutts. Jump over!")
				_hurt()
				break
	# Obstacles and enemies
	for t in things:
		if is_instance_valid(t) and t.alive and t.rect().grow(-6).intersects(me):
			_hurt()
	for c in chasers:
		if is_instance_valid(c) and c.kind == "tiger" and c.state == Chaser.State.WAITING and c.rect().grow(-10).intersects(me):
			_hurt()


func _headbutt_hit(t: Thing) -> void:
	if Progression.headbutt_breaks(stats, t.hp):
		t.knock_out()
		Audio.play("break")
		var enemy := bool(t.data.get("enemy", false))
		if enemy:
			enemies += 1
			SaveManager.count("enemies")
		if t.type == "bear":
			SaveManager.count("bears")
		elif t.type == "cowboy":
			SaveManager.count("cowboys")
		_reward(int(prog["xp"]["enemy"]) if enemy else 5, "BAM!", t.position + Vector2(0, -t.rect().size.y))
	else:
		_bonk("Too tough! Headbutt power %d needed" % t.hp)
		if t.data.get("hurts_on_bonk", false):
			_hurt()


func _bonk(text: String) -> void:
	Audio.play("bonk")
	stumble = 0.5
	x = maxf(0.0, x - 90)  # bounced back
	hud.float_text(text, Vector2(x, y - 150), UiTheme.PEACH)


func _hurt() -> void:
	if invulnerable > 0 or over:
		return
	hearts -= 1
	was_hit = true
	if autoplay:
		var near := []
		for t in things:
			if absf(t.position.x - x) < 200:
				near.append(t.type)
		for c in chasers:
			if absf(c.position.x - x) < 300:
				near.append(c.kind + str(c.state))
		print("  hit at %d m (surface %d, y %d): %s" % [metres(), surface, y, near])
	invulnerable = INVULNERABLE
	stumble = 0.4
	Audio.play("hurt")
	hud.shake()
	if surface >= 0:
		vy = -330
		surface = -1
	if hearts <= 0:
		_end(false)


func _on_bite(c: Chaser) -> void:
	if invulnerable > 0:
		return
	hud.float_text("Ouch! Bitten" if c.kind == "tiger" else "Bzzz! Bitten", Vector2(x, y - 140), Color(1, 0.6, 0.6))
	_hurt()


func _on_shot(from: Vector2) -> void:
	Audio.play("gunshot", randf_range(0.9, 1.1), -4)
	var b := Sprite2D.new()
	b.texture = load("res://art/new/bullet.png")
	b.position = from
	world.add_child(b)
	bullets.append({"node": b})


func _move_bullets(delta: float) -> void:
	var me := donkey_rect()
	for b in bullets.duplicate():
		var n: Sprite2D = b["node"]
		n.position.x -= 520 * delta
		if Rect2(n.position - Vector2(11, 5), Vector2(22, 10)).intersects(me):
			_hurt()
			n.queue_free()
			bullets.erase(b)
		elif n.position.x < x - 600:
			n.queue_free()
			bullets.erase(b)


func _reward(xp: int, text: String, at: Vector2) -> void:
	xp_run += xp
	hud.float_text("%s +%d XP" % [text, xp], at + Vector2(0, -40), UiTheme.CYAN)


# ------------------------------------------------------------------------------------------- the end

func _end(done: bool) -> void:
	if over:
		return
	over = true
	finished = done
	var m := int(minf(metres(), float(stage["length_m"])))
	var distance_xp := int(m / 10.0) * int(prog["xp"]["per_10_m"])
	var finish_xp := int(prog["xp"]["stage_finish"]) * int(str(stage["id"]).right(1)) if done else 0
	var total := xp_run + distance_xp + finish_xp
	SaveManager.count("distance_m", m)
	var level_before := SaveManager.level()
	var levels := SaveManager.add_xp(total)
	SaveManager.record_run(stage["id"], m, gas_got, layout["gas"].size(), done, was_hit)
	var new_achievements: Array = []
	for id in SaveManager.data["achievements"]:
		if not achievements_before.has(id):
			new_achievements.append(GameData.achievement(id).get("name", id))
	Audio.play("finish" if done else "hurt")
	if autoplay:
		print("AUTOPLAY %s finished=%s metres=%d hearts=%d/%d gas=%d/%d xp=%d" % [stage["id"], done, m, hearts, max_hearts, gas_got, layout["gas"].size(), total])
		if Router.params.has("quit"):
			get_tree().quit()
	hud.show_results({
		"finished": done, "metres": m, "length": int(stage["length_m"]),
		"gas": gas_got, "gas_total": layout["gas"].size(), "gas_name": world_data["gas_item_name"],
		"enemies": enemies, "xp_items": xp_run, "xp_distance": distance_xp, "xp_finish": finish_xp, "xp": total,
		"levels": levels, "level": level_before + levels, "achievements": new_achievements, "no_hit": done and not was_hit,
	})


func _autoplay() -> void:
	var lead := current_speed * 0.30 + 40.0
	for c in chasers:
		if is_instance_valid(c) and c.state == Chaser.State.CHASING and absf(c.position.x - x) < 240 and gas >= FART_COST:
			if c.kind == "mosquito" or Progression.scares_tiger(stats):
				do_fart()
				break
	if surface < 0:
		# Double jump over tall things while still rising.
		for t in things:
			if is_instance_valid(t) and t.alive and t.position.x > x and t.position.x - x < 160 and jumps == 1 and vy > -150:
				if y > t.rect().position.y - 10:
					do_jump()
		return
	var targets: Array = []
	for t in things:
		if is_instance_valid(t) and t.alive and int(t.tier) == surface:
			targets.append({"x": t.rect().position.x, "thing": t})
	for c in chasers:
		if is_instance_valid(c) and c.state == Chaser.State.WAITING and surface == 0:
			targets.append({"x": c.rect().position.x, "thing": null})
	for b in bullets:
		if b["node"].position.x > x:
			targets.append({"x": b["node"].position.x, "thing": null})
	targets.sort_custom(func(a, b): return a["x"] < b["x"])
	for tg in targets:
		var gap: float = tg["x"] - (x + HALF_W)
		if gap < -20:
			continue
		var t: Thing = tg["thing"]
		if t and t.data.get("air", 0) > 0:
			break  # a hive: just don't jump under it
		if t and Progression.headbutt_breaks(stats, t.hp):
			if gap < Progression.headbutt_reach(stats, prog) - 15:
				do_headbutt()
			break
		if gap < lead:
			do_jump()
		break


func next_stage_id() -> String:
	var ids := GameData.all_stage_ids()
	var i := ids.find(stage["id"])
	return ids[i + 1] if i >= 0 and i + 1 < ids.size() else ""
