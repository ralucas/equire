$ () ->

	socket = io.connect 'http://localhost'

	socket.on 'connect', () ->
		console.log 'hello sockets connected'

	$('#help-form').on 'submit', (e) ->
		e.preventDefault()
		newIssue = $('#issue').val()
		console.log newIssue
		socket.emit 'newIssue', newIssue
		$('#issue').val('')


		return
	return