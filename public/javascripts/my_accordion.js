$(document).ready(function() {
  $('#facets h3').next("ul, div").each(function() {
    var f_content = $(this);
    if ($('span.selected', f_content).length == 0) {
      var text = $('h3', f_content.parent()).text();
      $('h3', f_content.parent()).click(function() {
        $(f_content).slideToggle();
      });
    }
  });

  $('.contact_us h3').next("ul, div").each(function() {
    var f_content = $(this);
    f_content.hide();
    $('h3', f_content.parent()).click(function() {
      $(f_content).slideToggle();
    });
  });
});
