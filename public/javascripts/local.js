function crossfade(current_image, next_image) {
  if (next_image.is(':animated')) {
    next_image.stop().fadeTo(250, 1);
    current_image.fadeOut(250);
  }
  else {
    next_image.fadeIn(250);
    current_image.fadeOut(250);
  }
}

var image;
function rewrite_image() {
  $.get('/catalog/random', function(data) {
    image.html(data);
  });
}

function replace_image_left() {
  var current_image = $('.rotato > .current_image');
  var next_image = $('.rotato > .next_image');
  image = current_image;
  crossfade(current_image, next_image);
  setTimeout('rewrite_image();', 5000);
  setTimeout('replace_image_right();', 10000);
}

function replace_image_right() {
  var current_image = $('.rotato > .next_image');
  var next_image = $('.rotato > .current_image');
  image = current_image;
  crossfade(current_image, next_image);
  setTimeout('rewrite_image();', 5000);
  setTimeout('replace_image_left();', 10000);
}

jQuery(document).ready(function() {
	$("form.addFolder, form.deleteFolder").each(function() {
		var form = $(this);
		if(form.parent(".in_folder").length == 0){
			form.submit(function(){
                if (form.attr("action") == "/folder/destroy") {
                    form.find("input[type='image']").attr('src', '/images/add_to_folder.png').attr('title', 'Add to folder');
                }
                else {
                    form.find("input[type='image']").attr('src', '/images/remove_from_folder.png').attr('title', 'Remove from folder');
                }
				return false;
			});
	  }
	});	

  if ($("#more_formats_list").find(".format_select").size() == 0) {
    $("#more_formats_list").hide();
  }

  $(".more_formats").click(function() {
    $("#more_formats_list").slideToggle('fast');
  });
});
