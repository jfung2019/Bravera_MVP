//loading chartjs
import { Chart } from 'chart.js';

let myDistanceChart;
const distanceChartHook = {
	mounted() {
		var labels = []
		var values = []
		var distanceImages = []
		var backgroundColor = []
			
		let distanceJson = JSON.parse(this.el.dataset.json);

			var labels = distanceJson.map(function (index){
				return index.name;
			})
			var values = distanceJson.map(function (index){
				return index.value;
			})
			var newImages = distanceJson.map(function (index){
				return index.image;
			})
			var backgroundColor = distanceJson.map(function (index){
				return index.backgroundColor;
			})

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
						image.src = distanceImages[index],
						ctx.save();
						ctx.beginPath();
						ctx.arc(x, yAxis.bottom + 25, 13, 0, Math.PI * 2, false);
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
							return 'Distance: ' + dataset.data[index];
						}
					}
				},
				scales: {
					yAxes: [{
						ticks: {
							beginAtZero: true
						},
						gridLines : {
							borderDash: [2, 5],
						}
					}],
					xAxes: [{
						ticks: {
							padding: 40
						},
						gridLines : {
							display : false,
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
		myDistanceChart = new Chart(document.getElementById("myChartDistance"), config);
		myDistanceChart.data.labels.splice(0, myDistanceChart.data.labels.length, ...labels);
		myDistanceChart.data.datasets[0].labels.splice(0, myDistanceChart.data.datasets[0].labels.length, ...labels);
		myDistanceChart.data.datasets[0].data.splice(0, myDistanceChart.data.datasets[0].data.length, ...values);
		myDistanceChart.data.datasets[0].backgroundColor.splice(0, myDistanceChart.data.datasets[0].backgroundColor.length, ...backgroundColor);
		distanceImages = newImages;
		myDistanceChart.update();
	},
	updated() {
		var labels = []
		var values = []
		var distanceImages = []
		var backgroundColor = []
		let distanceJson = JSON.parse(this.el.dataset.json);
		
		var labels = distanceJson.map(function (index){
			return index.name;
		})
		var values = distanceJson.map(function (index){
			return index.value;
		})
		var newImages = distanceJson.map(function (index){
			return index.image;
		})
		var backgroundColor = distanceJson.map(function (index){
			return index.backgroundColor;
		})

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
						image.src = distanceImages[index],
						ctx.save();
						ctx.beginPath();
						ctx.arc(x, yAxis.bottom + 25, 13, 0, Math.PI * 2, false);
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
							return 'Distance: ' + dataset.data[index];
						}
					}
				},
				scales: {
					yAxes: [{
						ticks: {
							beginAtZero: true
						},
						gridLines : {
							borderDash: [2, 5],
						}
					}],
					xAxes: [{
						ticks: {
							padding: 40
						},
						gridLines : {
							color: "black",
							borderDash: [2, 5],
							display : false,
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
		if(myDistanceChart){
			myDistanceChart.destroy();
		}
		myDistanceChart = new Chart(document.getElementById("myChartDistance"), config);
		myDistanceChart.data.labels.splice(0, myDistanceChart.data.labels.length, ...labels);
		myDistanceChart.data.datasets[0].labels.splice(0, myDistanceChart.data.datasets[0].labels.length, ...labels);
		myDistanceChart.data.datasets[0].data.splice(0, myDistanceChart.data.datasets[0].data.length, ...values);
		myDistanceChart.data.datasets[0].backgroundColor.splice(0, myDistanceChart.data.datasets[0].backgroundColor.length, ...backgroundColor);
		distanceImages = newImages;
		myDistanceChart.update();
	}
};

export default distanceChartHook;