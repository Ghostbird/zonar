extends RigidBody2D

export(int) var SPEED = 600
export(int) var DAMAGE = 50

var initial_velocity = null

func _ready():
    if not initial_velocity:
        print("bullet no velocity")
        return
    linear_velocity = initial_velocity.normalized() * SPEED
    rotation = linear_velocity.angle()

func _on_lifetime_timeout():
    queue_free()

func _on_projectile_body_entered(body):
    queue_free()

func _on_hitbox_body_entered(body):
    #TODO works but could be better
    if body.has_method("_on_death"):
        queue_free()

    if body.has_method("_on_lose_health"):
        body.call("_on_lose_health", DAMAGE)
