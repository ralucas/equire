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
		$('#helptable tbody').append('<tr id="issueRow" class="animated flash"><td>'+
			'<input id="issueComplete" type="checkbox" data-id='+issue._id+'></td>'+
			'<td>'+issue.displayName+'</td><td id="issueTime">'+issue.time+'</td>'+
			'<td id="waitTime"></td><td>'+issue.issue+'</td></tr>')
		return

	#socket event placing now button click on teacher side
	socket.on 'asapIssue', (issue) ->
		$('#helptable tbody').append('<tr id="issueRow" class="animated flash"><td>'+
			'<input id="issueComplete" type="checkbox" data-id='+issue._id+'></td>'+
			'<td>'+issue.displayName+'</td><td id="issueTime">'+issue.time+'</td>'+
			'<td id="waitTime"></td><td>'+issue.issue+'</td></tr>')
			console.log($('#issueTime').text())
		return

	#put a clock on the teacher site
	clock = setInterval () ->
		timer()
	, 1000

	#creates the timer
	timer = () ->
		curr_time = moment().format('h:mm:ss a')
		$('#teacherclock').text(curr_time)
		$('#studentclock').text(curr_time)
		return

	#creates wait timer
	waitTime = setInterval () ->
	 	waitTimer()
	 , 10000

	waitTimer = () ->
		$('#waitTime').each (i) ->
			issue_time = $(@).prev().text()
			$(@).text(moment(issue_time).fromNow())
			console.log($(@).prev().text())
			return
		return

	#removes request on completion
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