###
Reports for Teacher Side
###

#Use filters and totals to pull differentiating reports

###
Functions
###



$ () ->
	#get all historical data
	$.get '/reportsInfo', (data) ->
		for eachIssue in data
			$('#reportsBody').append('<tr class="issueRow" data-id='+eachIssue['_id']+'>'+
					'<td class="displayName">'+eachIssue['displayName']+'</td>'+
					'<td class="issueTime" data-time='+eachIssue['timeStamp']+'>'+eachIssue['time']+'</td>'+
					'</td><td class="waitTime">'+moment().minutes(eachIssue['totalWait'])+'</td>'+
					'<td>'+eachIssue['lesson']+'</td>'+
					'<td>'+eachIssue['issue']+'</td>'+
					'<td>'+eachIssue['comment']+'</td>'+
					'</tr>')

	

	return