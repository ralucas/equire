$ () ->
	#instantiate sockets
	socket = io.connect 'http://localhost'

	socket.on 'connect', () ->
		console.log 'hello sockets connected'

	###
	Functions
	###

	#today's date
	today = moment().format('L')

	#put a clock on the teacher and student site
	clock = setInterval () ->
		timer()
	, 1000

	timer = () ->
		curr_time = moment().format('h:mm:ss a')
		$('#teacherclock').text(curr_time)
		$('#studentclock').text(curr_time)

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

	#issue edit
	issueEdit = (id, text) ->
		issueEditObj = {
			issueId : id,
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

	###
	Student side events	
	###

	#help now button click event
	$('#now-btn').on 'click', '#requestbtn', () ->
		username = $(@).closest('body').find('#user-dropdown a').attr('data-id')
		displayName = $(@).closest('body').find('#user-dropdown a').attr('data-user')
		issueCreation('Needs Help', username, displayName, false)
		$(@).removeClass('tada').addClass('slideOutRight')
		socket.on 'issue', (issue) ->
			$('#requestbtn').removeClass('show').addClass('hidden')
			$('#figurebtn').removeClass('slideOutLeft hidden').addClass('show animated slideInLeft')
			.attr('data-id',issue._id).attr('data-time',issue.timeStamp)

	#figured it out button click event
	$('#now-btn').on 'click', '#figurebtn', () ->
		issueId = $(@).attr('data-id')
		issueTime = $(@).attr('data-time')
		issueCompletion(issueId, issueTime, 'Figured out on own')
		$(@).removeClass('slideInLeft show').addClass('slideOutLeft hidden')
		$('#requestbtn').removeClass('slideOutRight hidden').addClass('slideInRight show')

	#issue form submission event
	$('#help-form').on 'submit', (e) ->
		e.preventDefault()
		newIssue = $('#issue').val()
		username = $(@).closest('body').find('#user-dropdown a').attr('data-id') 
		displayName = $(@).closest('body').find('#user-dropdown a').attr('data-user')
		issueId = $(@).closest('body').find('#figurebtn').attr('data-id')		
		if $(@).closest('body').find('#requestbtn').hasClass('show')
			$(@).closest('body').find('#requestbtn').removeClass('tada').addClass('slideOutRight')
			$(@).closest('body').find('#requestbtn').removeClass('show').addClass('hidden')
			$(@).closest('body').find('#figurebtn').removeClass('slideOutLeft hidden').addClass('show animated slideInLeft')
			issueCreation(newIssue, username, displayName, false)
		else issueEdit(issueId, newIssue)
		$('#issue').val('')
	
	#Current request table
	$.get '/currReq', (data) ->
		for eachIssue in data
			$('#currReqTable tbody').append('<tr class="issueRow" data-id='+eachIssue['_id']+'>'+
				'<td class="edit" data-toggle="modal" data-target="#editRequestModal">Edit</td>'+
				'<td class="issueTime" data-time='+eachIssue['timeStamp']+'>'+eachIssue['time']+'</td>'+
				'<td class="waitTime"></td>'+
				'<td class="issueDesc">'+eachIssue['issue']+'</td>'+
				'</tr>')

	#edit click that pulls up modal
	$('#currReqTable').on 'click', '.edit', () ->
		$('#modalIssue').empty()
		issueDesc = $(@).next().next().next().text()
		issueId = $(@).parent().attr('data-id')
		$(@).closest('body').find('#modalSave').attr('data-id', issueId)
		$(@).closest('body').find('#modalIssue').text(issueDesc)

	#on modal save updates db
	$('#editRequestModal').on 'click', '#modalSave', () ->
		editText = $(@).closest('.modal-content').find('#modalIssue').val()
		issueId = $(@).attr('data-id')
		issueEdit(issueId, editText)
		$('#editRequestModal').modal('hide')

	#socket event that updates pages
	socket.on 'issueEditObj', (issueEditObj) ->
		$('#helptable').find('.issueRow[data-id='+issueEditObj.issueId+']').find('.issueDesc')
		.text(issueEditObj.issue)
		$('#currReqTable').find('.issueRow[data-id='+issueEditObj.issueId+']').find('.issueDesc')
		.text(issueEditObj.issue)

	#Past request table
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
	$('#date').text(today).attr('data-date', today)

	$('#teacherInput').on 'submit', $('#lessonForm'), (e) ->
		e.preventDefault()
		todaysDate = $(@).closest('#teacherInput').find('#date').attr('data-date')
		lessonInput = $(@).find('#lessonInput').val()
		if lessonInput then $(@).closest('#teacherInput').slideUp() else alert 'Please enter a lesson plan'
		lessonUpdate = {
			date : todaysDate,
			lesson : lessonInput
		}
		socket.emit 'lessonUpdate', lessonUpdate

	#receive incomplete issues and load them into Help Requests
	$.get '/found', (data) ->
		for eachIssue in data
			$('#helptable tbody').append('<tr class="issueRow animated flash" data-id='+eachIssue['_id']+'>'+
				'<td><input class="issueComplete" type="checkbox" data-id='+eachIssue['_id']+'></td>'+
				'<td>'+eachIssue['displayName']+'</td>'+
				'<td class="issueTime" data-time='+eachIssue['timeStamp']+'>'+eachIssue['time']+'</td>'+
				'<td class="waitTime"></td>'+
				'<td class="issueDesc">'+eachIssue['issue']+'</td>'+
				'<td class="comment show">Add</td>'+
				'<td class="hidden commentbox"><form class="form-inline" role="form"><div class="input-group input-group-sm">'+
				'<input class="form-control input-sm" type="text" placeholder="Add comment...">'+
				'<span class="input-group-btn">'+
				'<button class="btn btn-default btn-sm" type="button">Add!</button>'+
				'</span></div></form></td>'+
				'</tr>')

	#socket event placing issues on teacher side
	socket.on 'issue', (issue) ->
		$('#helptable tbody').append('<tr class="issueRow animated flash" data-id='+issue._id+'>'+
			'<td><input class="issueComplete" type="checkbox" data-id='+issue._id+'></td>'+
			'<td>'+issue.displayName+'</td>'+
			'<td class="issueTime" data-time='+issue.timeStamp+'>'+issue.time+'</td>'+
			'<td class="waitTime"></td>'+
			'<td class="issueDesc">'+issue.issue+'</td>'+
			'<td class="comment show">Add</td>'+
			'<td class="hidden commentbox"><form class="form-inline" role="form"><div class="input-group input-group-sm">'+
			'<input class="form-control input-sm" type="text" placeholder="Add comment...">'+
			'<span class="input-group-btn">'+
			'<button class="btn btn-default btn-sm" type="button">Add!</button>'+
			'</span></div></form></td>'+
			'</tr>')

	###
	Idea: add sortability on current requests?
	###

	#click events to add comment
	$('#helptable').on 'click', '.comment', () ->
		$(@).removeClass('show').addClass('hidden')
		$(@).next('.commentbox').removeClass('hidden').addClass('show')

	$('#helptable').on 'submit', '.commentbox', (e) ->
		e.preventDefault()
		commentText = $(@).find('input').val()
		$(@).removeClass('show').addClass('hidden')
		$(@).prev('.comment').removeClass('hidden').text(commentText)

	#on check click event
	$('#helptable').on 'click', '.issueComplete', () ->
		issueId = $(@).attr('data-id')
		issueTime = $(@).closest('.issueRow').find('.issueTime').attr('data-time')
		comment = $(@).closest('.issueRow').find('.comment').text()
		if comment is 'Add'
			comment = 'Completed'
		else comment
		issueCompletion(issueId, issueTime, comment)

	#removes completed issue from help request list
	socket.on 'completeObj', (completeObj) ->
		$('#helptable').find('.issueRow[data-id='+completeObj.issueId+']').fadeOut('slow')
		$('#figurebtn').removeClass('slideInLeft show').addClass('slideOutLeft hidden')
		$('#requestbtn').removeClass('slideOutRight hidden').addClass('slideInRight show')
