import { Chart } from 'chart.js';

let myChart;
const distanceChartOrgHook = {
	mounted() {

    let distanceJson = JSON.parse(this.el.dataset.json);
    let group_longest = distanceJson.total_user_count_group_longest;
    let group_long = distanceJson.total_user_count_group_long;
    let group_moderate = distanceJson.total_user_count_group_moderate;
    let group_low = distanceJson.total_user_count_group_low;
    console.log(distanceJson)
    // console.log(`g333: is ${distanceJson[Object.keys(distanceJson)[0]].total_user_count_group_long}`);

    console.log(`total_user_count_group_longest: ${group_longest}`)
    console.log(`total_user_count_group_long: ${group_long}`)
    console.log(`total_user_count_group_moderate: ${group_moderate}`)
    console.log(`total_user_count_group_low: ${group_low}`)

    var labels = ['data group 1', 'data group 2','data group 3','data group 4']
    var values = [group_longest, group_long, group_moderate, group_low]
    var backgroundColor = ['#E53D4C', '#3D4EE5', '#CDF4AE', '#FFF1CC']  // red, blue, lime green, white yellow
    console.log(values)

		const config = {
      type: 'doughnut',
      data: {
        labels: labels,
        datasets: [{
          label: 'Data showing',
          data: values,
          backgroundColor: backgroundColor,
        }]
      },
      options: {
        legend: {
            display: false
        },
        tooltips: {
          callbacks: {
            label: function(tooltipItem, data) {
              //get the concerned dataset
              var dataset = data.datasets[tooltipItem.datasetIndex];
              //calculate the total of this data set
              var total = dataset.data.reduce(function(previousValue, currentValue, currentIndex, array) {
                return previousValue + currentValue;
              });
              //get the current items value
              var currentValue = dataset.data[tooltipItem.index];
              //calculate the precentage based on the total and current item, also this does a rough rounding to give a whole number
              var percentage = Math.floor(((currentValue/total) * 100)+0.5);
        
              return `${percentage}% (${currentValue})`;
            }
          }
        },
        plugins: {
          labels: {
            // Calculates the percentage number of each bar
            render: function (args) {  
              let max = 100; //Custom maximum value
              return Math.round(args.value * 100 / max ) + '%'; // show real percentage
            }
          }
        },
        onClick: (evt) => {
          var activePoints = myChart.getElementsAtEvent(evt);
          var chartData = activePoints[0]['_chart'].config.data;
          var idx = activePoints[0]['_index'];

          var label = chartData.labels[idx];
          var value = chartData.datasets[0].data[idx];
          var color = chartData.datasets[0].backgroundColor[idx];
          if (idx == 0) {
            console.log(`You Clicked group 1 longest`);
            // console.log(`You Clicked ${color}: ${label} with ${value}`);
          }else if (idx == 1) {
            console.log(`You Clicked group 2 long`);
            // console.log(`You Clicked ${color}: ${label} with ${value}`);
          }else if (idx == 2) {
            console.log(`You Clicked group 3 moderate`);
            // console.log(`You Clicked ${color}: ${label} with ${value}`);
          }else{
            console.log(`You Clicked group 4 low`);
            // console.log(`You Clicked ${color}: ${label} with ${value}`);
          }
        }
      }
    }
    myChart = new Chart(document.getElementById("myChartOrgDistance"), config);
    myChart.update();
	},
  updated() {
    let distanceJson = JSON.parse(this.el.dataset.json);
    let group_longest = distanceJson.total_user_count_group_longest;
    let group_long = distanceJson.total_user_count_group_long;
    let group_moderate = distanceJson.total_user_count_group_moderate;
    let group_low = distanceJson.total_user_count_group_low;

    console.log(`total_user_count_group_longest: ${group_longest}`)
    console.log(`total_user_count_group_long: ${group_long}`)
    console.log(`total_user_count_group_moderate: ${group_moderate}`)
    console.log(`total_user_count_group_low: ${group_low}`)

    var labels = ['data group 1', 'data group 2','data group 3','data group 4']
    var values = [group_longest, group_long, group_moderate, group_low]
    var backgroundColor = ['#E53D4C', '#3D4EE5', '#CDF4AE', '#FFF1CC']
    console.log(values)

		const config = {
      type: 'doughnut',
      data: {
        labels: labels,
        datasets: [{
          label: 'Data showing',
          data: values,
          backgroundColor: backgroundColor,
        }]
      },
      options: {
        legend: {
            display: false
        },
        tooltips: {
          callbacks: {
            label: function(tooltipItem, data) {
              //get the concerned dataset
              var dataset = data.datasets[tooltipItem.datasetIndex];
              //calculate the total of this data set
              var total = dataset.data.reduce(function(previousValue, currentValue, currentIndex, array) {
                return previousValue + currentValue;
              });
              //get the current items value
              var currentValue = dataset.data[tooltipItem.index];
              //calculate the precentage based on the total and current item, also this does a rough rounding to give a whole number
              var percentage = Math.floor(((currentValue/total) * 100)+0.5);
        
              return `${percentage}% (${currentValue})`;
            }
          }
        },
        plugins: {
          labels: {
            // Calculates the percentage number of each bar
            render: function (args) {  
              let max = 100; //Custom maximum value
              return Math.round(args.value * 100 / max ) + '%'; // show real percentage
            }
          }
        },
        onClick: (evt) => {
          var activePoints = myChart.getElementsAtEvent(evt);
          var chartData = activePoints[0]['_chart'].config.data;
          var idx = activePoints[0]['_index'];

          var label = chartData.labels[idx];
          var value = chartData.datasets[0].data[idx];
          var color = chartData.datasets[0].backgroundColor[idx];
        }
      }
    }
    if(myChart){
			myChart.destroy();
		}
    myChart = new Chart(document.getElementById("myChartOrgDistance"), config);
    myChart.update();
	}
};

export default distanceChartOrgHook;