$ () ->

#Pie Chart for who is requesting most
$.get '/pieChart', (data) ->
	console.log data



PieData = [
	{
		value: 30,
		color:"#F38630"
	},
	{
		value : 50,
		color : "#E0E4CC"
	},
	{
		value : 100,
		color : "#69D2E7"
	}			
]

ctx = $("#pieChart").get(0).getContext "2d"

newPieChart = new Chart(ctx).Pie(PieData)

#Line Chart for Requests by days of the week

linedata = {
	labels : ["Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"],
	datasets : [
		{
			fillColor : "rgba(220,220,220,0.5)",
			strokeColor : "rgba(220,220,220,1)",
			pointColor : "rgba(220,220,220,1)",
			pointStrokeColor : "#fff",
			data : [65,59,90,81,56,55,40]
		},
		{
			fillColor : "rgba(151,187,205,0.5)",
			strokeColor : "rgba(151,187,205,1)",
			pointColor : "rgba(151,187,205,1)",
			pointStrokeColor : "#fff",
			data : [28,48,40,19,96,27,100]
		}
	]
}

ctx = $("#lineChart").get(0).getContext "2d"

newLineChart = new Chart(ctx).Line(linedata)
