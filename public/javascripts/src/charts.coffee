$ () ->

#color randomizer function
colorRandomizer = () ->
	output = []
	colors = ''
	for i in 3
		output.push(Math.floor(Math.random()*255))
	colors = output.join(',')
	return 'rgb('+colors+')'

#Pie Chart for who is requesting most		
$.get '/pieChart', (data) ->
	pieData = []
	values = []
	for each, value of data
		values.push(value)
		obj = {
			name : each
			data : values
		}
		pieData.push(obj)
	$('#pieChart').highcharts {
		chart: {
			type: 'pie'
		},
		title: {
			text: 'Requests by User'
		},
		series: pieData
	}

#Line Chart for Requests by days of the week
$.get '/lineChart', (data) ->
	console.log data
	columnData = []
	days = []
	values = []
	for each, value of data
		values.push(value)
		days.push(each)
		obj = {
			name : each
			data : [value]
		}
		columnData.push(obj)
	console.log columnData
	$('#columnChart').highcharts {
		chart: {
			type: 'column'
		},
		title: {
			text: 'Requests by Days of the Week'
			},
		xAxis: {
			title: {
				text: 'Days of the Week'
			}
		},
		yAxis: {
			title: {
				text: 'Requests'
			},
			tickInterval: 1
		},
		series: columnData
	}
	lineData = {
		labels : days,
		datasets : [
			{
				fillColor : "rgba(151,187,205,0.5)",
				strokeColor : "rgba(151,187,205,1)",
				pointColor : "rgba(151,187,205,1)",
				pointStrokeColor : "#fff",
				data : values
			}
		]
	}
	line_options = {
		scaleStartValue : 0
	}
	ctx = $("#lineChart").get(0).getContext "2d"
	newLineChart = new Chart(ctx).Line(lineData, line_options)
