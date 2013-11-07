$ () ->
	#instantiate sockets
	socket = io.connect 'http://localhost'

	socket.on 'connect', () ->
		console.log 'hello sockets connected'

	###
	Functions
	###

	#put a clock on the teacher and student site
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
		$('.issueTime').each () ->
			currTime = moment().format('X')
			issueTime = $(@).attr('data-time')
			wait = currTime - issueTime
			waitConv = moment(issueTime*1000).fromNow()
			$(@).next('.waitTime').text(waitConv)
			
	#Create a new issue in database
	issueCreation = (newIssue, username, displayName, isComplete) ->
		issueObj = {
			newIssue : newIssue
			username : username,
			displayName : displayName
			isComplete : isComplete
		}
		socket.emit 'issueObj', issueObj
		return

	#issue edit
	issueEdit = (text) ->
		issueEditObj = {
			issue : text
		}
		socket.emit 'issueEditObj', issueEditObj

	#issue complete function
	issueCompletion = (issueId, issueTime, comment) ->
		currTime = moment().format('X')
		totalWait = currTime - issueTime
		completeObj = {
			issueId : issueId,
			totalWait : totalWait,
			isComplete : true,
			comment : comment
		}
		socket.emit 'completeObj', completeObj
		return

	###
	Student side events	
	###

	#help now button click event
	$('#now-btn').on 'click', '#requestbtn', () ->
		console.log 'click'
		username = $(@).closest('body').find('#user-dropdown a').attr('data-id')
		displayName = $(@).closest('body').find('#user-dropdown a').attr('data-user')
		issueCreation('Needs Help', username, displayName, false)
		$(@).removeClass('tada').addClass('slideOutRight')
		socket.on 'issue', (issue) ->
			$('#requestbtn').addClass('hidden')
			$('#figurebtn').removeClass('slideOutLeft hidden').addClass('show animated slideInLeft')
			.attr('data-id',issue._id).attr('data-time',issue.timeStamp)
			return
		return

	#figured it out button click event
	$('#now-btn').on 'click', '#figurebtn', () ->
		issueId = $(@).attr('data-id')
		issueTime = $(@).attr('data-time')
		console.log issueTime
		issueCompletion(issueId, issueTime, 'Figured out on own')
		$(@).removeClass('slideInLeft show').addClass('slideOutLeft hidden')
		$('#requestbtn').removeClass('slideOutRight hidden').addClass('slideInRight show')
		return

	#issue form submission event
	$('#help-form').on 'submit', (e) ->
		e.preventDefault()
		newIssue = $('#issue').val()
		username = $(@).closest('body').find('#user-dropdown a').attr('data-id')
		displayName = $(@).closest('body').find('#user-dropdown a').attr('data-user')
		issueCreation(newIssue, username, displayName, false)
		$('#issue').val('')
		return
	
	#current request table
	$.get '/currReq', (data) ->
		for eachIssue in data
			$('#currReqTable tbody').append('<tr class="issueRow" data-id='+eachIssue['_id']+'>'+
				'<td class="edit" data-toggle="modal" data-target="#editRequestModal">Edit</td>'+
				'<td class="issueTime" data-time='+eachIssue['timeStamp']+'>'+eachIssue['time']+'</td>'+
				'<td class="waitTime"></td>'+
				'<td class="issueDesc">'+eachIssue['issue']+'</td>'+
				'</tr>')

	$('#currReqTable').on 'click', '.edit', () ->
		$('#modalIssue').empty()
		issueDesc = $(@).next().next().next().text()
		console.log issueDesc
		$(@).closest('body').find('#modalIssue').text(issueDesc)

	$('#modalSave').on 'click', () ->
		editText = $(@).closest('.modal-content').find('#modalIssue').text()
		issueEditText(editText)

	#past request table
	$.get '/pastReq', (data) ->
		for eachIssue in data
			$('#pastReqTable tbody').append('<tr class="issueRow" data-id='+eachIssue['_id']+'>'+
				'<td class="issueTime" data-time='+eachIssue['timeStamp']+'>'+eachIssue['time']+'</td>'+
				'</td><td class="waitTime">'+moment().minutes(eachIssue['totalWait'])+'</td>'+
				'<td>'+eachIssue['issue']+'</td>'+
				'<td>'+eachIssue['comment']+'</td>'+
				'</tr>')

	###
	Teacher side events	
	###

	#lesson plan submission event
	$('#teacherInput').on 'submit', $('#lessonForm'), (e) ->
		e.preventDefault()
		console.log 'lesson click'
		lessonInput = $(@).find('#lessonInput').val()
		if lessonInput then $(@).closest('#teacherInput').slideUp() else alert 'Please enter a lesson plan'
		socket.emit 'lessonInput', lessonInput
		return

	#receive incomplete issues and load them into Help Requests
	$.get '/found', (data) ->
		for eachIssue in data
			$('#helptable tbody').append('<tr class="issueRow animated flash" data-id='+eachIssue['_id']+'>'+
				'<td><input class="issueComplete" type="checkbox" data-id='+eachIssue['_id']+'></td>'+
				'<td>'+eachIssue['displayName']+'</td>'+
				'<td class="issueTime" data-time='+eachIssue['timeStamp']+'>'+eachIssue['time']+'</td>'+
				'<td class="waitTime"></td><td>'+eachIssue['issue']+'</td>'+
				'</tr>')
		return

	#socket event placing issues on teacher side
	socket.on 'issue', (issue) ->
		$('#helptable tbody').append('<tr class="issueRow animated flash" data-id='+issue._id+'>'+
			'<td><input class="issueComplete" type="checkbox" data-id='+issue._id+'></td>'+
			'<td>'+issue.displayName+'</td>'+
			'<td class="issueTime" data-time='+issue.timeStamp+'>'+issue.time+'</td>'+
			'<td class="waitTime"></td><td>'+issue.issue+'</td>'+
			'</tr>')
		return

	#on check click event
	$('#helptable').on 'click', '.issueComplete', () ->
		console.log('checked')
		issueId = $(@).attr('data-id')
		issueTime = $(@).closest('.issueRow').find('.issueTime').attr('data-time')
		issueCompletion(issueId, issueTime, 'completed')
		return

	#removes completed issue from help request list
	socket.on 'completeObj', (completeObj) ->
		$('#helptable').find('.issueRow[data-id='+completeObj.issueId+']').fadeOut('slow')
		return
	return