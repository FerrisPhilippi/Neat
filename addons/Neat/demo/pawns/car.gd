extends RigidBody2D

signal death

@onready var left_ray: RayCast2D = $raycasts/left
@onready var down_ray: RayCast2D = $raycasts/down
@onready var right_ray: RayCast2D = $raycasts/right
@onready var up_ray: RayCast2D = $raycasts/up
@onready var raycasts: Node2D = $raycasts
var casters: Array[RayCast2D] = []
var timer_time = 1
# Driving Properties
var acceleration = 15
var max_forward_velocity = 1000
var drag_coefficient = 0.99 # Recommended: 0.99 - Affects how fast you slow down
var steering_torque = 6 # Affects turning speed
var steering_damp = 8 # 7 - Affects how fast the torque slows down


# Drifting & Tire Friction
var can_drift = true
var wheel_grip_sticky = 0.85 # Default drift coef (will stick to road, most of the time)
var wheel_grip_slippery = 0.99 # Affects how much you "slide"
var drift_extremum = 250 # Right velocity higher than this will cause you to slide
var drift_asymptote = 20 # During a slide you need to reduce right velocity to this to gain control
var _drift_factor = wheel_grip_sticky # Determines how much (or little) your vehicle drifts

# Vehicle velocity and angular velocity. Override rigidbody velocity in physics process
var _velocity = Vector2.ZERO
var _angular_velocity = 0

# vehicle forward speed
var speed: int = 70
var fitness: float = 0.0

func _ready() -> void:
	casters.append(left_ray)
	casters.append(right_ray)
	casters.append(down_ray)
	casters.append(up_ray)
	$Timer.start(timer_time)
	
	var start_pos = global_position
	await get_tree().create_timer(5).timeout
	if (global_position - start_pos).length() <= 15:
		die()

func get_right_velocity() -> Vector2:
	# Returns the vehicle's sidewards velocity
	return -transform.x * _velocity.dot(-transform.x)

func get_up_velocity() -> Vector2:
	# Returns the vehicle's forward velocity
	return -transform.y * _velocity.dot(-transform.y)

func sense() -> Array:
	var senses = []
	
	for caster: RayCast2D in casters:
		if caster.is_colliding():
			var collision = caster.get_collision_point()
			var distance = (collision - global_position).length()
			var relative_distance = remap(distance, 0, 50, 0, 2)
			senses.append(relative_distance)
		else:
			senses.append(1)
	
	return senses

func act(actions: Array) -> void:
	var torque = lerp(0, steering_torque, _velocity.length() / max_forward_velocity)
	# accelerate
	if actions[0] > 0.3:
		_velocity += -transform.y * acceleration
	# break & reverse
	elif actions[1] > 0.3:
		_velocity -= -transform.y * acceleration
	# steer right
	if actions[2] > 0.1:
		_angular_velocity = remap(actions[2], 0.2, 1, 0, 1) * torque * sign(speed)
	# steer left
	elif actions[3] > 0.1:
		_angular_velocity = remap(actions[3], 0.2, 1, 0, 1) * -torque * sign(speed)
	# Prevent exceeding max velocity
	var max_speed = (Vector2(0, -1) * max_forward_velocity).rotated(rotation)
	var x = clamp(_velocity.x, -abs(max_speed.x), abs(max_speed.x))
	var y = clamp(_velocity.y, -abs(max_speed.y), abs(max_speed.y))
	_velocity = Vector2(x, y)
	
	
	if _drift_factor == wheel_grip_sticky and get_right_velocity().length() > drift_extremum:
		_drift_factor = wheel_grip_slippery
		# If we are sliding on the road
	elif get_right_velocity().length() < drift_asymptote:
		_drift_factor = wheel_grip_sticky
	# Add drift to velocity
	_velocity = get_up_velocity() + (get_right_velocity() * _drift_factor)
	# Override Rigidbody movement
	set_linear_velocity(_velocity)
	set_angular_velocity(_angular_velocity)
	# Update the forward speed
	speed = -get_up_velocity().dot(transform.y)

func get_fitness() -> float:
	return fitness

func die():
	death.emit()
	hide()

func _on_area_2d_area_entered(area: Area2D) -> void:
	if area.is_in_group("border"):
		die()
	elif area.is_in_group("checkpoint"):
		fitness += 10


func _on_timer_timeout() -> void:
	fitness += 0.1
	$Timer.start(timer_time)
