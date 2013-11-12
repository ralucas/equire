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
totalsObj = {}

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

	#builds totals object
	totalsBuild = (arr) ->
		totalIssues = arr.length
		sumWait = _.reduce arr, ((memo, index) -> 
			memo + index['totalWait']),0
		avg = sumWait/totalIssues
		avgWait = Math.round(avg/60)
		console.log 'aw', avgWait
		countDate = _.countBy(arr, 'date')
		dates = _.pluck(arr, 'date')
		for each in dates
			days.push(moment(each).format('dddd'))
		daysCount = _.countBy(days)

		totalsObj = {
			totalIssues : totalIssues,
			avgWait : avgWait,
			countDate : countDate,
			countDay : countDay,
			countTerm : countTerm,
			countStudent : countStudent
		}
		totalsTable(totalsObj)

	#builds totals table on page
	totalsTable = (obj) ->
		$('#summaryBody').empty()

	#get all historical data
	$.get '/reportsInfo', (data) ->
		issueData = data
		buildTable(issueData)
		totalsBuild(issueData)
			
	#sorts on header click
	$('th').each () ->
		$(@).on 'click', () ->
			if $(@).hasClass('sorted')
				$(@).addClass('reverse').removeClass('sorted')
				rsd = sortedData.reverse()
				console.log 'rsd', rsd
				buildTable(rsd)
			else
				$(@).addClass('sorted').removeClass('reverse')
				value = $(@).attr('data-type')
				sortedData = _.sortBy(issueData, (arr) ->
					return arr[value])
				console.log 'sd', sortedData
				buildTable(sortedData)

	#filter data
	filter = (arr, key, value1, value2) ->
		output = []
		for each in arr
			if each[key] >= value1 and each[key] <= value2
				output.push(each)
		return output
	
	#totals
	

	

	###
	Filter/Search by name, date, time range, time waited, lesson, issue, comment
	###

	#Search menu select events
	$('.search-menu').on 'click', () ->
		index = $(@).attr('data-type')
		srchText = $(@).text()
		$searchInput = $(@).closest('#reports').find('.search-input')
		$searchInput.find('.search-btn').text('Search by '+srchText).attr('data-type', index)
		$searchInput.removeClass('hidden').addClass('open')

	$('#reports').on 'click', '.search-btn', (e) ->
		e.preventDefault()
		$searchval = $(@).closest('.search-input').find('#search-value')
		searchValue = $searchval.val()
		index = $(@).attr('data-type')
		searchResults = search(issueData, searchValue, index)
		buildTable(searchResults)
		$searchval.val('')

	$('#reports').on 'click', '.cancel-search', (e) ->
		e.preventDefault()
		$searchInput = $(@).closest('#reports').find('.search-input')
		$searchInput.addClass('hidden').removeClass('show')

	#filter by date range
	$('#reports').on 'click', '#date-btn', () ->
		$('.date-row').removeClass('hidden').addClass('open')

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
		$('.time-row').removeClass('hidden').addClass('open')

	$('#reports').on 'click', '#cancel-time', () ->
		$('.time-row').addClass('hidden')

	$('#reports').on 'click', '#submit-time', () ->
		fromTime = moment($("#fromTime").val()).format()
		console.log fromTime
		toTime = $("#toTime").val()
		filteredData = filter(issueData, "date", fromTime, toTime)
		buildTable(filteredData)

	#reset filter button
	$('#reports').on 'click', '.reset-btn', () ->
		if $(@).closest('.container').find('.filter-input').hasClass('open')
			console.log 'whats up'
			$(@).closest('.container').find('.filter-input').removeClass('open').addClass('hidden')
		else
			console.log 'no reset'
		buildTable(issueData)

	return