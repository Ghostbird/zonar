extends Sprite

onready var break_timer = $BreakTimer

func _input(event):
    if visible != true:
        return
    if event.is_action_pressed("break_block"):
        break_timer.start()
    if event.is_action_released("break_block"):
        break_timer.stop()
