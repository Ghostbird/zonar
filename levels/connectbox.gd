extends PanelContainer

func disable():
	$vbox/hbox_buttons/host.disabled = true
	$vbox/hbox_buttons/join.disabled = true
	$vbox/hbox/color.disabled = true
	$vbox/hbox/username.editable = false
	$vbox/server_address.editable = false
	$vbox/error.text = ''
	$vbox/error.hide()

func enable(with_error=''):
	$vbox/hbox_buttons/host.disabled = false
	$vbox/hbox_buttons/join.disabled = false
	$vbox/hbox/color.disabled = false
	$vbox/hbox/username.editable = true
	$vbox/server_address.editable = true
	$vbox/error.text = with_error
	$vbox/error.show()