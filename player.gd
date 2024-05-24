extends CharacterBody2D

enum State {
	IDLE,
	RUNNING,
	JUMP,
	FALL,
	LANDING,
	WALLSLIDING,
	WALLJUMP,
	ATTACK1,
	ATTACK2,
	ATTACK3,
	HURT,
	DIE
}

@export var can_combo := false

const GROUND_STATE = [State.IDLE, State.RUNNING,State.LANDING,State.ATTACK1,State.ATTACK2,State.ATTACK3]

const RUN_SPEED := 200.0
const JUMP_VELOCITY: float = -400.0
const AIR_ACCELERATION := RUN_SPEED * 10
const FLOOR_ACCELERATION := RUN_SPEED * 20
const WALL_JUMP_VELOCITY := Vector2(RUN_SPEED*0.8,JUMP_VELOCITY*0.8)

var is_first_tick := false
var is_combo_requested := false
var pending_damage:Damage

var default_gravity := ProjectSettings.get("physics/2d/default_gravity") as float
@onready var graphics: Node2D = $Graphics
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var jumprequest_timer: Timer = $JumprequestTimer

@onready var hand_checker: RayCast2D = $Graphics/HandChecker
@onready var foot_checker: RayCast2D = $Graphics/FootChecker
@onready var state_machine: StateMachine = $StateMachine
@onready var stats: Stats = $Stats
@onready var invincible_timer: Timer = $InvincibleTimer


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("jump"):
		jumprequest_timer.start()
	if event.is_action_released("jump"):
		jumprequest_timer.stop()
		if velocity.y < JUMP_VELOCITY /2:
			velocity.y = JUMP_VELOCITY/2
	if event.is_action_pressed("attack") and can_combo:
		is_combo_requested = true

func tick_physics(state:State,delta: float) -> void:
	if invincible_timer.time_left > 0:
		graphics.modulate.a = sin(Time.get_ticks_msec()/20) * 0.5 + 0.5
	else:
		graphics.modulate.a = 1
	match state:
		State.IDLE:
			move(default_gravity,delta)
		State.RUNNING:
			move(default_gravity,delta)
		State.JUMP:
			move(default_gravity,delta)
		State.FALL:
			move(default_gravity,delta)
		State.LANDING:
			stand(default_gravity,delta)
		State.WALLSLIDING:
			move(default_gravity/2,delta)
			graphics.scale.x = get_wall_normal().x # 蹬墙要反转
		State.WALLJUMP:
			if state_machine.state_time < 0.1:
				stand(0.0 if is_first_tick else default_gravity,delta)
				graphics.scale.x =get_wall_normal().x
			else:
				move(default_gravity,delta)
		State.ATTACK1,State.ATTACK2,State.ATTACK3:
			stand(default_gravity,delta)
		State.HURT,State.DIE:
			stand(default_gravity,delta)

func die() -> void:
	get_tree().reload_current_scene()
			
func stand(gravity: float,delta: float) -> void:
	var acceleration := FLOOR_ACCELERATION if is_on_floor() else AIR_ACCELERATION
	velocity.x = move_toward(velocity.x, 0.0,acceleration * delta)
	
	velocity.y += gravity * delta
	move_and_slide()
	
func move(gravity: float,delta:float) -> void:
	var direction := Input.get_axis("move_left","move_right")
	var acceleration := FLOOR_ACCELERATION if is_on_floor() else AIR_ACCELERATION
	velocity.x = move_toward(velocity.x, direction * RUN_SPEED,acceleration* delta)
	
	velocity.y += gravity * delta
	
	if not is_zero_approx(direction):
		graphics.scale.x = -1 if direction < 0 else 1
	
	move_and_slide()

func get_next_state(state: State) -> int:
	if stats.health == 0:
		return StateMachine.KEEP_CURRENT if state == State.DIE else State.DIE
	
	if pending_damage:
		return State.HURT
	var direction := Input.get_axis("move_left","move_right")
	var is_still := is_zero_approx(direction) and is_zero_approx(velocity.x)
	
	var can_jump = is_on_floor()
	var should_jump = can_jump and not jumprequest_timer.is_stopped()
	if should_jump:
		if state != State.FALL:
			if state_machine.state_time > 0.1:
				return State.JUMP
	
	if state in GROUND_STATE and not is_on_floor():
		return State.FALL
	match state:
		State.IDLE:
			if not is_still:
				return State.RUNNING
			if Input.is_action_just_pressed("attack"):
				return State.ATTACK1
		State.RUNNING:
			if is_still:
				return State.IDLE
			if Input.is_action_just_pressed("attack"):
				return State.ATTACK1
		State.JUMP:
			if velocity.y >=0:
				return State.FALL
		State.FALL:
			if is_on_floor():
				return State.LANDING if is_still else State.RUNNING
			if is_on_wall() and hand_checker.is_colliding() and foot_checker.is_colliding():
				return State.WALLSLIDING
		State.LANDING:
			if not is_still:
				return State.RUNNING
			if not animation_player.is_playing():
				return State.IDLE
		State.WALLSLIDING:
			if jumprequest_timer.time_left > 0:
				if state_machine.state_time > 0.1:
					return State.WALLJUMP
			if is_on_floor():
				return State.IDLE
			if not is_on_wall():
				return State.FALL
		State.WALLJUMP:
			if is_on_wall() and not is_first_tick:
				return State.WALLSLIDING
			if velocity.y >=0:
				return State.FALL
		State.ATTACK1:
			if not animation_player.is_playing():
				return State.ATTACK2 if is_combo_requested else State.IDLE
		State.ATTACK2:
			if not animation_player.is_playing():
				return State.ATTACK3 if is_combo_requested else State.IDLE
		State.ATTACK3:
			if not animation_player.is_playing():
				return State.IDLE
		State.HURT:
			if not animation_player.is_playing():
				return State.IDLE
	return StateMachine.KEEP_CURRENT

func transition_state(from: State,to: State) -> void:
	print("[%s] %s => %s"%[
		Engine.get_physics_frames(),
		State.keys()[from] if from != -1 else "nil",
		State.keys()[to]
	])
	if from != to:
		is_first_tick = true
	match to:
		State.IDLE:
			animation_player.play("idle")
		State.RUNNING:
			animation_player.play("running")
		State.JUMP:
			animation_player.play("jump")
			velocity.y = JUMP_VELOCITY
		State.FALL:
			animation_player.play("fall")
		State.LANDING:
			animation_player.play("landing")
		State.WALLSLIDING:
			animation_player.play("wall_sliding")
		State.WALLJUMP:
			velocity = WALL_JUMP_VELOCITY
			velocity.x *= get_wall_normal().x
			animation_player.play("running")
		State.ATTACK1:
			animation_player.play("attack1")
			is_combo_requested = false
		State.ATTACK2:
			animation_player.play("attack2")
			is_combo_requested = false
		State.ATTACK3:
			animation_player.play("attack3")
			is_combo_requested = false
		State.HURT:
			animation_player.play("hurt")
			stats.health -=pending_damage.amount
			
			var dir := pending_damage.source.global_position.direction_to(global_position)
			velocity = dir * 400
			
			pending_damage = null
			invincible_timer.start()
		State.DIE:
			animation_player.play("die")
			invincible_timer.stop()

func _on_hurtbox_hurt(hitbox: Variant) -> void:
	if invincible_timer.time_left >0:
		return
	pending_damage = Damage.new()
	pending_damage.amount =1
	pending_damage.source = hitbox.owner
