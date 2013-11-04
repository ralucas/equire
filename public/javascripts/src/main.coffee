$ () ->

	socket = io.connect 'http://localhost'

	socket.on 'connect', () ->
		console.log 'hello sockets connected'

	# $.get '/student', #{user}, (data) ->
	# 	console.log 'hi'
	# 	console.log data
	# 	return

	$('#now-btn').on 'click', 'button', () ->
		username = $(@).closest('body').find('#user-dropdown a').attr('data-id')
		name = $(@).closest('body').find('#user-dropdown a').text()
		console.log name
		return

	$('#help-form').on 'submit', (e) ->
		e.preventDefault()
		newIssue = $('#issue').val()
		username = $(@).closest('body').find('#user-dropdown a').attr('data-id')
		name = $(@).closest('body').find('#user-dropdown a').text()
		console.log newIssue
		issueObj = {
			newIssue : newIssue,
			username : username,
			name : name
		}
		console.log issueObj
		socket.emit 'issueObj', issueObj
		$('#issue').val('')
		return
	
	$('#teacherinput').on 'submit', $('#lesson-plan'), (e) ->
		e.preventDefault()
		lessonplan = $(@).find('#lessonplan').val()
		if lessonplan then $(@).closest('#teacherinput').slideUp() else alert 'Please enter a lesson plan'
		return

	socket.on 'issue', (issue) ->
		console.log 'hi'
		console.log issue
		$('#helprequests').append('<p class="lead">Issue: '+issue.issue+' Name: '+issue.username+
			' Time: '+issue.time+'</p>')
		return
	return