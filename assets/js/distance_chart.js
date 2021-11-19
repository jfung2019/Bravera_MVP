//loading chartjs
import { Chart } from 'chart.js';


const distanceChartHook = {
	mounted() {
		var labels = []
		var values = []
		var distanceImages = []
		var backgroundColor = []

		const config = {
			type: "bar", //bar, horizontalBar, pie, line, doughnut, radar, polarArea
			plugins: [{
				afterDraw: chart => {
					var ctx = chart.ctx;
					var xAxis = chart.scales['x-axis-0'];
					var yAxis = chart.scales['y-axis-0'];
					xAxis.ticks.forEach((value, index) => {
						var x = xAxis.getPixelForTick(index);
						var image = new Image();
						image.src = distanceImages[index],
							ctx.drawImage(image, x - 12, yAxis.bottom + 10);
					});
				}
			}],
			data: {
				labels: labels,
				datasets: [{
					label: 'Data',
					labels: labels,
					data: values,
					backgroundColor: backgroundColor,
					barPercentage: 0.8, // width of bar
				}]
			},
			options: {
				responsive: true,
				legend: {
					display: false
				},
				tooltips: {
					callbacks: {
						label: function (tooltipItem, data) {
							var dataset = data.datasets[tooltipItem.datasetIndex];
							var index = tooltipItem.index;
							return 'Distance: ' + dataset.data[index];
						}
					}
				},
				scales: {
					yAxes: [{
						ticks: {
							beginAtZero: true
						}
					}],
					xAxes: [{
						ticks: {
							padding: 40
						}
					}],
				},
				plugins: {
					labels: {
						// Calculates the percentage number of each bar
						render: function (args) {
							//let max = 100; //Custom maximum value
							// return Math.round(args.value * 100 / max ) + '%'; // show real percentage
							return ''; // dont show percentage
						}
					}
				}
			}
		}
		var myDistanceChart = new Chart(document.getElementById("myChartDistance"), config);

		this.handleEvent("distance_data", ({ distance_data }) => {
			var labels = distance_data.map(function (item) {
				return item.name;
			})
			var values = distance_data.map(function (item) {
				return item.value;
			})
			var newImages = distance_data.map(function (item) {
				return item.image;
			})
			var backgroundColor = distance_data.map(function (item) {
				return item.backgroundColor;
			})



			myDistanceChart.data.labels.splice(0, myDistanceChart.data.labels.length, ...labels);
			myDistanceChart.data.datasets[0].labels.splice(0, myDistanceChart.data.datasets[0].labels.length, ...labels);
			myDistanceChart.data.datasets[0].data.splice(0, myDistanceChart.data.datasets[0].data.length, ...values);
			myDistanceChart.data.datasets[0].backgroundColor.splice(0, myDistanceChart.data.datasets[0].backgroundColor.length, ...backgroundColor);
			distanceImages = newImages;
			myDistanceChart.update();

		});


	}
};

export default distanceChartHook;