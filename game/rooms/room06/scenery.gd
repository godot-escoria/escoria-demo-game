extends Node


const CLOUDX_RESET = 1320
const CLOUDX_MIN = 585
const CLOUDX_SPEED = 55
const WAVE_SPEED = 3
const WAVE_HEIGHT = 30
const WAVE_LENGTH = 60

var wave_counter = 0
var cloud_1x = CLOUDX_RESET
var cloud_1y

var cloud_2x = CLOUDX_RESET + 180
var cloud_2y


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Randomise the random number generator
	randomize()
	# Set random y offsets for the 2 clouds
	cloud_1y = randi() % 175 + 60
	cloud_2y = randi() % 175 + 60


func animate_cloud(delta) -> void:
	# For both clouds, move them across the sky.
	# If they disappear behind the boat, reset them back offscreen
	cloud_1x -= CLOUDX_SPEED * delta
	if cloud_1x < CLOUDX_MIN:
		cloud_1x = CLOUDX_RESET
		cloud_1y = randi() % 175 + 60
	$cloud.set_position(Vector2(cloud_1x, cloud_1y))
	cloud_2x -= CLOUDX_SPEED * delta
	if cloud_2x < CLOUDX_MIN:
		cloud_2x = CLOUDX_RESET
		cloud_2y = randi() % 175 + 60
	$cloud2.set_position(Vector2(cloud_2x, cloud_2y))


func animate_waves(delta) -> void:
	# Constantly increment the wave counter which generates a circle shape over time
	wave_counter += delta

	# Each wave has an offset (0/0.8/1.6) which offsets their rotation from each other
	# They also have a different x and y offset from each other
	# Wave 1
	var c1_xlocation = 520 + (sin(1.6 + wave_counter * WAVE_SPEED) * WAVE_LENGTH)
	var c1_ylocation = 560 + (cos(1.6 + wave_counter * WAVE_SPEED) * WAVE_HEIGHT)
	$wave.set_position(Vector2(c1_xlocation, c1_ylocation))

	# Wave 2
	var c2_xlocation = 620 + (sin(0.8 + wave_counter * WAVE_SPEED) * WAVE_LENGTH)
	var c2_ylocation = 530 + (cos(0.8 + wave_counter * WAVE_SPEED) * WAVE_HEIGHT)
	$wave2.set_position(Vector2(c2_xlocation, c2_ylocation))

	# Wave 3
	var c3_xlocation = 720 + (sin(wave_counter * WAVE_SPEED) * WAVE_LENGTH)
	var c3_ylocation = 500 + (cos(wave_counter * WAVE_SPEED) * WAVE_HEIGHT)
	$wave3.set_position(Vector2(c3_xlocation, c3_ylocation))


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# Animate the waves
	animate_waves(delta)
	# Animate the clouds
	animate_cloud(delta)
