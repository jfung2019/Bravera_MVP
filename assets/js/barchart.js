//loading chartjs
import { Chart } from 'chart.js';
import 'chartjs-plugin-labels';
import 'babel-core/register';
import 'babel-polyfill';

const chartHook = {
  mounted() {
    const jsonData = JSON.parse(this.el.dataset.json);
    var getUsernameLocal = jsonData.Result.Users.map(function (index){
      return index.name;
    })
    var getUserValueLocal = jsonData.Result.Users.map(function (index){
      return index.value;
    })
    var getUserImageLocal= jsonData.Result.Users.map(function (index){
      return index.image;
    })
    var getUserBackgroundLocal= jsonData.Result.Users.map(function (index){
      return index.backgroundColor;
    })

    // set variable to array result from json
    var labels = getUsernameLocal;
    var values = getUserValueLocal.sort((a,b)=>b-a);
    var images = getUserImageLocal;
    var backgroundColor = getUserBackgroundLocal;


    function updateChart () {
      async function fetchData(){
        const url = "http://127.0.0.1:5500/data.json";
        const response = await fetch(url);
        const dataPoint = await response.json();
        return dataPoint;
      }
    
      fetchData().then(dataPoint => {
        const getUsername = dataPoint.Result.Users.map(function (index){
          return index.name;
        })
        const getUserValue = dataPoint.Result.Users.map(function (index){
          return index.value;
        })
        var getUserImage = dataPoint.Result.Users.map(function (index){
          return index.image;
        })
        var getUserBackground = dataPoint.Result.Users.map(function (index){
          return index.backgroundColor;
        })
        // myChart.config.data.labels = getUsername;
        // myChart.config.data.datasets[0].data = getUserValue.sort((a,b)=>b-a);
        // myChart.config.data.datasets[0].backgroundColor = getUserBackground;
        // images = getUserImage;
        // myChart.update();
      })
    }

    const configSync = {
        type: "bar", //bar, horizontalBar, pie, line, doughnut, radar, polarArea
        plugins: [{
          afterDraw: chart => {      
            var ctx = chart.ctx; 
            var xAxis = chart.scales['x-axis-0'];
            var yAxis = chart.scales['y-axis-0'];
            xAxis.ticks.forEach((value, index) => {  
              var x = xAxis.getPixelForTick(index);      
              var image = new Image();
              image.src = images[index],
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
              label: function(tooltipItem, data) {
                  var dataset = data.datasets[tooltipItem.datasetIndex];
                  var index = tooltipItem.index;
                  var getUserIndex = dataset.labels[index];
                  var userIndex = dataset.labels.indexOf(getUserIndex);
                  return '#' + (userIndex + 1) + ' | Sync Activity: ' + dataset.data[index];
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
    const configSocial = {
      type: "bar", //bar, horizontalBar, pie, line, doughnut, radar, polarArea
      plugins: [{
        afterDraw: chart => {      
          var ctx = chart.ctx; 
          var xAxis = chart.scales['x-axis-0'];
          var yAxis = chart.scales['y-axis-0'];
          xAxis.ticks.forEach((value, index) => {  
            var x = xAxis.getPixelForTick(index);      
            var image = new Image();
            image.src = images[index],
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
            label: function(tooltipItem, data) {
                var dataset = data.datasets[tooltipItem.datasetIndex];
                var index = tooltipItem.index;
                var getUserIndex = dataset.labels[index];
                var userIndex = dataset.labels.indexOf(getUserIndex);
                return '#' + (userIndex + 1) + ' | Sync Activity: ' + dataset.data[index];
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
            image.src = images[index],
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
            label: function(tooltipItem, data) {
                var dataset = data.datasets[tooltipItem.datasetIndex];
                var index = tooltipItem.index;
                var getUserIndex = dataset.labels[index];
                var userIndex = dataset.labels.indexOf(getUserIndex);
                return '#' + (userIndex + 1) + ' | Sync Activity: ' + dataset.data[index];
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
    var myChart = new Chart(document.getElementById("myChartDistance"), config);
    var myChart = new Chart(document.getElementById("myChartSync"), configSync);
    var myChart = new Chart(document.getElementById("myChartSocial"), configSocial);
    //filter array: label, images, values
    //array.filter
    //create new arrays 
    //for loop
    
    document.getElementById("filter").addEventListener("click", function() {
      // filter array
      // const filterResult = myChart.data.datasets[0].labels.filter(data => data.includes('J'));
      
      // create new array based on the filter and use this in datasets
      // const filterLabel = [];
      // const filterData = [];
      // const filterImages = [];
      // console.log(filterResult);

      //loop
      // var i=0;
      // for (i=0; i < filterResult.length; i++){
      //   myChart.data.datasets[0].labels.indexOf(filterResult[i]);
      //   console.log(myChart.data.datasets[0].labels.indexOf(filterResult[i]));
      // }
      updateChart ();
      console.log('update');
    });
  }
};






export default chartHook;