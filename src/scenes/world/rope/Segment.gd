extends RigidBody2D

var colliding : bool

const color = [Color.TRANSPARENT, Color.GREEN]

func _ready():
	mass = 10
	linear_damp = 5
	angular_damp = 5
	pass
