###
Reports for Teacher Side
###

#Use filters and totals to pull differentiating reports

###
Functions
###

issueData = []
sortedData = []
filteredData = []

$ () ->

	#builds table function
	buildTable = (arr) ->
		$('#reportsBody').empty()
		for each in arr
			$('#reportsBody').append('<tr class="issueRow" data-id='+each['_id']+'>'+
					'<td class="displayName">'+each['displayName']+'</td>'+
					'<td class="issueTime" data-time='+each['timeStamp']+'>'+each['time']+'</td>'+
					'</td><td class="waitTime">'+moment().minutes(each['totalWait'])+'</td>'+
					'<td>'+each['lesson']+'</td>'+
					'<td>'+each['issue']+'</td>'+
					'<td>'+each['comment']+'</td>'+
					'</tr>')

	#get all historical data
	$.get '/reportsInfo', (data) ->
		issueData = data
		buildTable(issueData)
			
	#sorts on header click
	$('th').each () ->
		$(@).on 'click', () ->
			value = $(@).attr('data-type')
			sortedData = _.sortBy(issueData, (arr) ->
				return arr[value])
			buildTable(sortedData)

	#filter data
	filter = (arr, key, value1, value2) ->
		output = []
		for each in arr
			if each[key] >= value1 and each[key] <= value2
				output.push(each)
		return output
	
	#totals
	# $.get '/names', (data) ->
	# 	console.log data

	

	###
	Filter/Search by name, date, time range, time waited, lesson, issue, comment
	###

	#Search menu select events
	$('.search-menu').on 'click', () ->
		index = $(@).attr('data-type')
		$searchInput = $(@).closest('#reports').find('.search-input')
		$searchInput.find('.search-btn').text('Search by '+index).attr('data-type', index)
		$searchInput.removeClass('hidden')

	$('#reports').on 'click', '.search-btn', (e) ->
		e.preventDefault()
		$searchval = $(@).closest('.search-input').find('#search-value')
		searchValue = $searchval.val()
		index = $(@).attr('data-type')
		searchResults = search(issueData, searchValue, index)
		buildTable(searchResults)
		$searchval.val('')

	#reset filter button
	$('#reports').on 'click', '.reset-btn', () ->
		if $('.filter-input').hasClass('hidden')
		else $('.filter-input').addClass('hidden')
		buildTable(issueData)

	#filter by date range
	$('#reports').on 'click', '#date-btn', () ->
		console.log 'button clicked'
		$('.date-row').removeClass('hidden')

	$("#fromDate").datepicker {
		defaultDate: 0,
		changeMonth: true,
		numberOfMonths: 1,
		onClose: (selectedDate) ->
			$("#toDate").datepicker "option", "minDate", selectedDate
		}

	$("#toDate").datepicker {
		defaultDate: "+1w",
		changeMonth: true,
		numberOfMonths: 1,
		onClose: (selectedDate) ->
			$("#fromDate").datepicker "option", "maxDate", selectedDate
		}

	$('#reports').on 'click', '#cancel-date', () ->
		$('.date-row').addClass('hidden')

	$('#reports').on 'click', '#submit-date', () ->
		fromDate = $("#fromDate").val()
		toDate = $("#toDate").val()
		filteredData = filter(issueData, "date", fromDate, toDate)
		buildTable(filteredData)

	#filter by time
	$('#fromTime').timepicker({ 'timeFormat': 'h:i A' })
	$('#toTime').timepicker({ 'timeFormat': 'h:i A' })

	$('#reports').on 'click', '#time-btn', () ->
		console.log 'button clicked'
		$('.time-row').removeClass('hidden')

	$('#reports').on 'click', '#cancel-time', () ->
		$('.time-row').addClass('hidden')

	$('#reports').on 'click', '#submit-time', () ->
		fromTime = moment($("#fromTime").val()).format()
		console.log fromTime
		toTime = $("#toTime").val()
		filteredData = filter(issueData, "date", fromTime, toTime)
		buildTable(filteredData)

	return