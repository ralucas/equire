###
Reports for Teacher Side
###

issueData = []
lessonData = []
sortedData = []
filteredData = []
totalsObj = {}

$ () ->

	#converts seconds to minutes
	secToMin = (seconds) ->
		minutes = Math.ceil(seconds/60)
		if minutes is 1 then return 'Less than a minute'
		else
			return minutes+' minutes'

	#builds table function
	buildTable = (arr) ->
		$('#reportsBody').empty()
		for each in arr
			tw = each['totalWait']
			ttw = secToMin(tw)
			$('#reportsBody').append('<tr class="issueRow" data-id='+each['_id']+'>'+
					'<td class="displayName">'+each['displayName']+'</td>'+
					'<td class="issueTime" data-time='+each['timeStamp']+'>'+each['time']+'</td>'+
					'<td class="reportwaitTime">'+ttw+'</td>'+
					'<td>'+each['issue']+'</td>'+
					'<td>'+each['comment']+'</td>'+
					'</tr>')

	#builds totals object
	totalsBuild = (arr) ->
		#total issues
		totalIssues = arr.length
		#avg wait time
		sumWait = _.reduce arr, ((memo, index) -> 
			memo + index['totalWait']),0
		avg = sumWait/totalIssues
		avgWait = Math.round(avg/60)
		#requests by date
		countDate = _.countBy(arr, 'date')
		mostDate = _.pick(_.invert(countDate), _.max(countDate))
		#requests by days
		dates = _.pluck(arr, 'date')
		days = []
		for each in dates
			days.push(moment(each).format('dddd'))
		countDay = _.countBy(days)
		dayObj = _.pick(_.invert(countDay), _.max(countDay))
		#most term in requests
		reqTerms = _.pluck(arr, 'issue')
		strTerms = reqTerms.join(' ').split(' ')
		countTerms = _.countBy(strTerms)
		mostTerm = _.pick(_.invert(countTerms), _.max(countTerms))
		#most term in comments
		reqComms = _.pluck(arr, 'comment')
		strComms = reqTerms.join(' ').split(' ')
		countComms = _.countBy(strComms)
		mostComm = _.pick(_.invert(countComms), _.max(countComms))
		#student with most requests
		names = _.pluck(arr, 'displayName')
		strNames = names.join(' ').split(' ')
		countNames = _.countBy(strNames)
		mostStudent = _.pick(_.invert(countNames), _.max(countNames))
		#total object
		totalsObj = {
			totalIssues : totalIssues,
			avgWait : avgWait,
			mostDate : mostDate,
			mostDay : dayObj,
			mostTerm : _.values(mostTerm).join(),
			mostComm : _.values(mostComm).join(),
			mostStudent : _.values(mostStudent).join()
		}
		totalsTable(totalsObj)

	#builds totals table on page
	totalsTable = (obj) ->
		$('#summaryBody').empty()
		$('#summaryBody').append('<tr class="summaryRow">'+
			'<td>'+obj['totalIssues']+'</td>'+
			'<td>'+obj['avgWait']+'</td>'+
			'<td>'+_.keys(obj['mostDate']).join()+'</td>'+
			'<td>'+_.keys(obj['mostDay']).join()+'</td>'+
			'<td>'+obj['mostTerm']+'</td>'+
			'<td>'+obj['mostComm']+'</td>'+
			'<td>'+obj['mostStudent']+'</td>'+
			'</tr>')
		$('#summaryHeaders').find('.date-thead').text('Date with Most Requests: '+_.values(obj['mostDate']).join())
		$('#summaryHeaders').find('.day-thead').text('Day with Most Requests: '+_.values(obj['mostDay']).join())

	#get all historical data
	$.get '/reportsInfo', (data) ->
		issueData = data
		buildTable(issueData)
		totalsBuild(issueData)

	$.get 'lessonInfo', (data) ->
		lessonData = data
			
	#sorts on header click
	$('th').each () ->
		$(@).on 'click', () ->
			if $(@).hasClass('sorted')
				$(@).addClass('reverse').removeClass('sorted')
				rsd = sortedData.reverse()
				buildTable(rsd)
			else
				$(@).addClass('sorted').removeClass('reverse')
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

	filterTime = (arr, key, value1, value2) ->
		output = []
		for each in arr
			if moment(each[key]).format('HH:mm:ss') >= value1 and moment(each[key]).format('HH:mm:ss') <= value2
				output.push(each)
		return output
	
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
	$('#fromTime').timepicker({ 'timeFormat': 'H:i:s' })
	$('#toTime').timepicker({ 'timeFormat': 'H:i:s' })

	$('#reports').on 'click', '#time-btn', () ->
		$('.time-row').removeClass('hidden').addClass('open')

	$('#reports').on 'click', '#cancel-time', () ->
		$('.time-row').addClass('hidden')

	$('#reports').on 'click', '#submit-time', () ->
		fromTime = $("#fromTime").val()
		toTime = $("#toTime").val()
		filteredData = filterTime(issueData, "time", fromTime, toTime)
		buildTable(filteredData)

	#reset filter button
	$('#reports').on 'click', '.reset-btn', () ->
		if $(@).closest('.container').find('.filter-input').hasClass('open')
			$(@).closest('.container').find('.filter-input').removeClass('open').addClass('hidden')
		else
			console.log 'no reset'
		buildTable(issueData)

	#student summary report
	buildSummaryTable = (arr, key, headings) ->
		$sumTable = $('#summaryReports').find('#summaryReportsTable')
		$sumTable.find('thead').empty()
		$sumTable.find('tbody').empty()
		$sumTable.find('thead').append('<tr><th>'+headings[0]+'</th>'+
			'<th>'+headings[1]+'</th></tr>')
		requestsCount = _.countBy(issueData, key)
		for each, qty of requestsCount
			$sumTable.find('tbody').append('<tr>'+
				'<td>'+each+'</td>'+
				'<td>'+qty+'</td></tr>')

	$('#userSumBtn').on 'click', () ->
		buildSummaryTable(issueData, 'displayName', ['Name', 'Number of Requests'])

	$('#dateSumBtn').on 'click', () ->
		buildSummaryTable(issueData, 'date', ['Date', 'Number of Requests'])

	$('#summResetBtn').on 'click', () ->
		$sumTable = $(@).closest('#summaryReports').find('#summaryReportsTable')
		$sumTable.find('thead').empty()
		$sumTable.find('tbody').empty()

	return
