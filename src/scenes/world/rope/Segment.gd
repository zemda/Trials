extends RigidBody2D

var colliding : bool

const color = [Color.RED, Color.GREEN]

func _ready():
	pass

func _physics_process(_delta):
	
	colliding = get_colliding_bodies().size() > 0
	modulate = color[int(colliding)]
	
	#deform()

func deform():
	var scale_x = 0.2
	var scale_y = 0.6
	var scale_range = 0.1
	var deform = clamp((scale_range / 80) * 1, 0, scale_range)
	
	$Sprite2D.scale = Vector2((scale_x - deform), (scale_y + deform))
