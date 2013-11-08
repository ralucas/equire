###
Reports for Teacher Side
###

#Use filters and totals to pull differentiating reports

###
Functions
###

issueData = []

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

	#totals


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
		if $('.search-input').hasClass('hidden')
		else $('.search-input').addClass('hidden')
		buildTable(issueData)

	#filter by date range
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

	return