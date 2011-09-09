$(function () {
  var displayed = 0;
  var count = $('.slideshow .pic').length;

  $(document).keydown(function(e){
    var bindings = [[37, -1], [39, 1]];
    for (var i in bindings) {
      if (e.keyCode == bindings[i][0]) {
        $('.slideshow #pic_' + displayed).first().hide();
        displayed += bindings[i][1];
        if (displayed < 0)
          displayed = count - 1;
        else if (displayed == count)
          displayed = 0;
        $('.slideshow #pic_' + displayed).first().show();
        return false;
      }
    }
  });

  $('.slideshow .pic').first().show();
});
