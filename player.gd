extends CharacterBody2D

enum State {
	IDLE,
	RUNNING,
	JUMP,
	FALL,
	LANDING,
	WALLSLIDING,
	WALLJUMP
}

const GROUND_STATE = [State.IDLE, State.RUNNING]

const RUN_SPEED := 200.0
const JUMP_VELOCITY: float = -400.0
const AIR_ACCELERATION := RUN_SPEED * 10
const FLOOR_ACCELERATION := RUN_SPEED * 20
const WALL_JUMP_VELOCITY := Vector2(RUN_SPEED*0.8,JUMP_VELOCITY*0.8)

var is_first_tick := false

var default_gravity := ProjectSettings.get("physics/2d/default_gravity") as float
@onready var graphics: Node2D = $Graphics
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var jumprequest_timer: Timer = $JumprequestTimer

@onready var hand_checker: RayCast2D = $Graphics/HandChecker
@onready var foot_checker: RayCast2D = $Graphics/FootChecker
@onready var state_machine: StateMachine = $StateMachine


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("jump"):
		jumprequest_timer.start()
	if event.is_action_released("jump"):
		jumprequest_timer.stop()
		if velocity.y < JUMP_VELOCITY /2:
			velocity.y = JUMP_VELOCITY/2
		

func tick_physics(state:State,delta: float) -> void:
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
			
func stand(gravity: float,delta: float) -> void:
	var acceleration := FLOOR_ACCELERATION if is_on_floor() else AIR_ACCELERATION
	velocity.x = move_toward(velocity.x, 0.0,acceleration/20* delta)
	
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

func get_next_state(state: State) ->State:
	var direction := Input.get_axis("move_left","move_right")
	var is_still := is_zero_approx(direction) and is_zero_approx(velocity.x)
	
	var can_jump = is_on_floor()
	var should_jump = can_jump and not jumprequest_timer.is_stopped()
	if should_jump:
		if state != State.FALL:
			if state_machine.state_time > 0.1:
				return State.JUMP
	match state:
		State.IDLE:
			if not is_still:
				return State.RUNNING
			if not is_on_floor():
				return State.FALL
		State.RUNNING:
			if is_still:
				return State.IDLE
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
				
	return state

func transition_state(from: State,to: State) -> void:
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