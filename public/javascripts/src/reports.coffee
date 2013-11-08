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

	###
	Filter by name, date, time range, time waited, lesson, issue, comment
	###

	###
	Search by name, data, time range, time waited, lesson, issue, comment
	###
	return