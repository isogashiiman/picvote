$(document).keydown(function(e){
  var bindings = [[37, "prev"], [39, "next"], [38, "vote"], [40, "unvote"]];
  for (var i in bindings) {
    var id = "a#" + bindings[i][1];
    if (e.keyCode == bindings[i][0] && $(id).length > 0) {
      document.location = $(id).attr("href");
      return false;
    }
  }
});
$('#liked').delay(1000).fadeOut();
$('#unliked').delay(1000).fadeOut();
$(document).ready(function() { $("abbr.timeago").timeago(); });
