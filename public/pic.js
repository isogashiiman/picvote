$(document).keydown(function(e){
  if (e.keyCode == 37 && $("a#prev").length > 0) {
    document.location = $("a#prev").attr("href");
    return false;
  } else if (e.keyCode == 39 && $("a#next").length > 0) {
    document.location = $("a#next").attr("href");
    return false;
  }
});
