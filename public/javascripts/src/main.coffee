$ () ->
	#instantiate sockets
	socket = io.connect 'http://localhost'

	socket.on 'connect', () ->
		console.log 'hello sockets connected'

	#receive incomplete issues and load them into Help Requests
	$.get '/found', (data) ->
		console.log data
		for eachIssue in data
			console.log 'i', eachIssue['_id']
			$('#helptable tbody').append('<tr class="issueRow animated flash"><td>'+
				'<input class="issueComplete" type="checkbox" data-id='+eachIssue['_id']+'></td>'+
				'<td>'+eachIssue['displayName']+'</td><td class="issueTime" data-time='+eachIssue['timeStamp']+
				'>'+eachIssue['time']+'</td><td class="waitTime"></td><td>'+eachIssue['issue']+'</td></tr>')
		return

	# socket.on 'found', (issue) ->
	# 	console.log issue
	# 	for i in issue
	# 		console.log 'i', i['_id']
	# 		$('#helptable tbody').append('<tr class="issueRow animated flash"><td>'+
	# 			'<input class="issueComplete" type="checkbox" data-id='+[i]['_id']+'></td>'+
	# 			'<td>'+[i]['displayName']+'</td><td class="issueTime" data-time='+[i]['timeStamp']+
	# 			'>'+[i]['time']+'</td><td class="waitTime"></td><td>'+[i]['issue']+'</td></tr>')
	# 	return

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
		$('#helptable tbody').append('<tr class="issueRow animated flash"><td>'+
			'<input class="issueComplete" type="checkbox" data-id='+issue._id+'></td>'+
			'<td>'+issue.displayName+'</td><td class="issueTime" data-time='+issue.timeStamp+
			'>'+issue.time+'</td><td class="waitTime"></td><td>'+issue.issue+'</td></tr>')
		return

	#socket event placing now button click on teacher side
	socket.on 'asapIssue', (issue) ->
		$('#helptable tbody').append('<tr class="issueRow animated flash"><td>'+
			'<input class="issueComplete" type="checkbox" data-id='+issue._id+'></td>'+
			'<td>'+issue.displayName+'</td><td class="issueTime" data-time='+issue.timeStamp+
			'>'+issue.time+'</td><td class="waitTime"></td><td>'+issue.issue+'</td></tr>')
		return

	#put a clock on the teacher site
	clock = setInterval () ->
		timer()
	, 1000

	timer = () ->
		curr_time = moment().format('h:mm:ss a')
		$('#teacherclock').text(curr_time)
		$('#studentclock').text(curr_time)
		return

	#creates wait timer and checks it every 1 second
	setInterval () ->
		waitTimer()
	, 1000

	waitTimer = () ->
		$('.waitTime').each () ->
			curr_time = moment().format('X')
			issue_time = $(@).prev().attr('data-time')
			issue_time_int = parseInt(issue_time)
			iti = +moment(issue_time_int)
			console.log parseInt(issue_time)
			console.log moment(issue_time).fromNow()
			$(@).text(moment(issue_time).fromNow())
			return
		return

	#removes request on completion
	$('#helptable').on 'click', '.issueComplete', () ->
		console.log('checked')
		curr_time = moment().format('X')
		console.log 'ct', curr_time
		issueId = $(@).attr('data-id')
		issue_time = $(@).closest('.issueRow').find('.issueTime').attr('data-time')
		console.log 'it', issue_time
		totalWait = curr_time - issue_time
		console.log 'tw', totalWait
		completeObj = {
			issueId : issueId,
			totalWait : totalWait,
			isComplete : true
		}
		console.log 'co', completeObj
		socket.emit 'completeObj', completeObj
		$(@).closest('.issueRow').fadeOut('slow')
		return
	return