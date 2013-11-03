$ () ->

	socket = io.connect 'http://localhost'

	socket.on 'connect', () ->
		console.log 'hello sockets connected'

	# $.get '/student', #{user}, (data) ->
	# 	console.log 'hi'
	# 	console.log data
	# 	return

	$('#help-form').on 'submit', (e) ->
		e.preventDefault()
		newIssue = $('#issue').val()
		console.log newIssue
		socket.emit 'newIssue', newIssue
		$('#issue').val('')
		return
	
	$('#teacherinput').on 'submit', $('#lesson-plan'), (e) ->
		e.preventDefault()
		lessonplan = $(@).find('#lessonplan').val()
		if lessonplan then $(@).closest('#teacherinput').slideUp() else alert 'Please enter a lesson plan'

		return

	return