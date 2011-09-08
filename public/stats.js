function plot_per_user(data) {
  var numbers = [];
  var labels = [];
  var tooltips = [];
  for (key in data) {
    numbers.push(data[key]);
    labels.push(key);
    tooltips.push(key + ":<br/>" + data[key]);
  }
  $(".chart#per_user").chart({
    template: "pie_1",
    values: { serie1: numbers },
    labels: labels,
    legend: labels,
    tooltips: { serie1: tooltips },
  });
}

function plot_votes_count(data) {
  var numbers = [];
  var labels = [];
  var tooltips = [];
  for (key in data) {
    numbers.push(data[key]);
    var tip;
    if (key == 1)
      tip = "1 vote";
    else
      tip = key + " votes";
    labels.push(tip);
    tooltips.push(tip + ":<br/>" + data[key]);
  }
  $(".chart#votes_count").chart({
    template: "pie_1",
    values: { serie1: numbers },
    labels: labels,
    legend: labels,
    tooltips: { serie1: tooltips },
  });
}

function plot(data) {
  plot_per_user(data.per_user);
  plot_votes_count(data.votes_count);
}

$.elycharts.templates['pie_1'] = {
  type: "pie",
  defaultSeries: {
    plotProps: {
      stroke: "white",
      "stroke-width": 1,
      opacity: 0.8
    },
    highlight: {
      move: 10
    },
    tooltip: {
      frameProps: {
        opacity: 0.7
      }
    },
    values: [
      { plotProps: { fill: "red" } },
      { plotProps: { fill: "blue" } },
      { plotProps: { fill: "green" } },
      { plotProps: { fill: "brown" } },
      { plotProps: { fill: "purple" } },
      { plotProps: { fill: "orange" } },
      { plotProps: { fill: "silver" } },
      { plotProps: { fill: "black" } },
    ] },
  features: {
    legend: {
      horizontal: false,
      width: 80,
      height: 80,
      x: 252,
      y: 218,
      borderProps: {
        "fill-opacity": 0.3
      }
    }
  }
};
