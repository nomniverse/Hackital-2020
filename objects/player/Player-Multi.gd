extends BasePlayer

class_name PlayerMulti

# == Export Variables ==
export var player_id : int = 1
export var player_name : String = "Player 1"

# == Node References ==
onready var playerUsername = $PlayerUsername

# == Puppet Variables ==
puppet var puppet_velocity = Vector2()
puppet var puppet_ball_count = 0

func _physics_process(delta):
	var move_dir = 0
	
	if is_network_master():
		if Input.is_action_pressed("player_one_move_right"):
			move_dir += 1
		if Input.is_action_pressed("player_one_move_left"):
			move_dir -= 1
		
		is_jumping = Input.is_action_just_pressed("player_one_jump")
		is_attacking = Input.is_action_pressed("player_one_tag")
		
		velocity = Vector2(move_dir * MOVE_SPEED, velocity.y + GRAVITY)
		
		var on_floor = is_on_floor()
		var on_ceiling = is_on_ceiling()
		
		if on_floor:
			if is_jumping:
				velocity.y = -JUMP_FORCE
		
			if velocity.y >= 5:
				velocity.y = 5
		
		if on_ceiling:
			velocity.y = 1
			
		if velocity.y > MAX_FALL_SPEED:
			velocity.y = MAX_FALL_SPEED
			
		var _linear_velocity = move_and_slide(velocity, Vector2(0, -1))
		
		rset_unreliable("puppet_velocity", velocity)
		
		if ball_count == MAX_BALLS:
			for i in get_slide_count():
				var collision = get_slide_collision(i)
				
				if collision.collider is Ball:
					collision.collider.set_velocity(collision.collider.get_velocity() + velocity)
		
		if is_attacking and can_shoot and ball_count > 0:
			rpc("_attack", player_id)
			ball_count -= 1
			rset("puppet_ball_count", ball_count)
	
			can_shoot = false
			throwTimer.start()
		
		if (facing_right and move_dir < 0) or (!facing_right and move_dir > 0):
			rpc("_flip")
			
		if is_on_floor():
			if move_dir == 0:
				rpc("_play_anim", "idle")
			else:
				rpc("_play_anim", "walk")
		else:
			rpc("_play_anim", "jump")
	else:
		move_and_slide(puppet_velocity, Vector2(0, -1))
		
		ball_count = puppet_ball_count
		
		if puppet_ball_count == MAX_BALLS:
			for i in get_slide_count():
				var collision = get_slide_collision(i)
				
				if collision.collider is Ball:
					collision.collider.set_velocity(collision.collider.get_velocity() + puppet_velocity)

func pick_up_ball():
	if ball_count + 1 <= MAX_BALLS:
		ball_count += 1
		
		if is_network_master():
			rset("puppet_ball_count", ball_count)
			
		return true
	else:
		return false

# Called when the node enters the scene tree for the first time.
func _ready():
	original_position = global_position
	
	playerUsername.text = player_name
	
func tag():
	get_parent().rpc("reset_map")
	
func get_player_id():
	return player_id

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func _on_ThrowTimer_timeout():
	can_shoot = true
