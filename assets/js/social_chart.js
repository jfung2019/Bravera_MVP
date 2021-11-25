//loading chartjs
import { Chart } from 'chart.js';

const socialChartHook = {
	mounted() {
		var labels = []
		var values = []
		var socialImages = []
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
						var imageSize = 30;
						image.src = socialImages[index],
						ctx.save();
						ctx.beginPath();
						ctx.arc(x, yAxis.bottom + 25, 15, 0, Math.PI * 2, false);
						ctx.clip();
						ctx.drawImage(image, x - 15, yAxis.bottom + 12, imageSize, imageSize);
						ctx.restore();
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
							return 'Social Activity: ' + dataset.data[index];
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
		var mySocialChart = new Chart(document.getElementById("myChartSocial"), config);

		this.handleEvent("social_data", ({ social_data }) => {
			var labels = social_data.map(function (item) {
				return item.name;
			})
			var value = social_data.map(function (item) {
				return item.value;
			})
			var newImages = social_data.map(function (item) {
				return item.image;
			})
			var backgroundColor = social_data.map(function (item) {
				return item.backgroundColor;
			})

			mySocialChart.data.labels.splice(0, mySocialChart.data.labels.length, ...labels);
			mySocialChart.data.datasets[0].labels.splice(0, mySocialChart.data.datasets[0].labels.length, ...labels);
			mySocialChart.data.datasets[0].data.splice(0, mySocialChart.data.datasets[0].data.length, ...value);
			mySocialChart.data.datasets[0].backgroundColor.splice(0, mySocialChart.data.datasets[0].backgroundColor.length, ...backgroundColor);
			socialImages = newImages;
			mySocialChart.update();

		});


	}
};

export default socialChartHook;