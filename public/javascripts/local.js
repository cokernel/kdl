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
});
