$ () ->
	#instantiate sockets
	socket = io.connect 'http://localhost'

	socket.on 'connect', () ->
		console.log 'hello sockets connected'

	#now button click event
	$('#now-btn').on 'click', 'button', () ->
		console.log 'click'
		username = $(@).closest('body').find('#user-dropdown a').attr('data-id')
		displayName = $(@).closest('body').find('#user-dropdown a').attr('data-user')
		asapObj = {
			username : username,
			displayName : displayName
		}
		console.log asapObj
		socket.emit 'asapObj', asapObj
		return

	#issue form submission event
	$('#help-form').on 'submit', (e) ->
		e.preventDefault()
		newIssue = $('#issue').val()
		username = $(@).closest('body').find('#user-dropdown a').attr('data-id')
		displayName = $(@).closest('body').find('#user-dropdown a').attr('data-user')
		
		issueObj = {
			newIssue : newIssue,
			username : username,
			displayName : displayName
		}
		socket.emit 'issueObj', issueObj
		$('#issue').val('')
		return
	
	#lesson plan submission event
	$('#teacherinput').on 'submit', $('#lesson-plan'), (e) ->
		e.preventDefault()
		lessonplan = $(@).find('#lessonplan').val()
		if lessonplan then $(@).closest('#teacherinput').slideUp() else alert 'Please enter a lesson plan'
		return

	#socket event placing issues on teacher side
	socket.on 'issue', (issue) ->
		$('#helptable tbody').append('<tr id="issueRow" class="animated flash"><td><input id="issueComplete" type="checkbox" data-id='+issue._id+'></td>'+
			'<td>'+issue.displayName+'</td><td>'+issue.time+'</td><td>'+issue.issue+'</td></tr>')
		return

	#socket event placing now button click on teacher side
	socket.on 'asapIssue', (issue) ->
		$('#helptable tbody').append('<tr id="issueRow" class="animated flash"><td><input id="issueComplete" type="checkbox" data-id='+issue._id+'></td>'+
			'<td>'+issue.displayName+'</td><td>'+issue.time+'</td><td>'+issue.issue+'</td></tr>')
		return

	$('#helptable').on 'click', '#issueComplete', () ->
		console.log('checked')
		issueId = $(@).attr('data-id')
		completeObj = {
			issueId : issueId,
			isComplete : true
		}
		socket.emit 'isComplete', completeObj
		$(@).closest('#issueRow').fadeOut('slow')
		return
	return