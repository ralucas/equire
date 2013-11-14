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
	seriesData = _.pairs(data)
	$('#pieChart').highcharts {
		chart: {
			plotBackgroundColor: null,
			plotBorderWidth: null,
			plotShadow: false
		},
		title: {
			text: 'Requests by User'
		},
		plotOptions: {
			pie: {
				allowPointSelect: true,
				cursor: 'pointer',
				dataLabels: {
					enabled: true,
					color: '#000000',
					connectorColor: '#000000',
					formatter: () ->
						return '<b>'+this.point.name+'</b>: '+this.y
				}
			}
		},
		series: [{
			type: 'pie',
			name: 'Requests'
			data: seriesData
			}] 
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
