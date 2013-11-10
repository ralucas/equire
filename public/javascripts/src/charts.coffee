$ () ->

testdata = [
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

ctx = $("#myChart").get(0).getContext "2d"

myNewChart = new Chart(ctx).Pie(testdata)

