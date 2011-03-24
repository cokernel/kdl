$(document).ready(function() {
    $('#facets h3').next("ul, div").each(function(){
   var f_content = $(this);
   // find all f_content's that don't have any span descendants with a class of "selected"
   if($('span.selected', f_content).length == 0){
        // hide it
        var text = $('h3', f_content.parent()).text();

        /* Eventum request 440 (Search Facet Drop Downs in Blacklight):
           In the same manner that we adjusted the Format facet to display its contents 
           at all times, eliminating the drop down feature, I would like to do the same 
           for all search facets used.
        if (text != 'Format') {
          f_content.hide();
        }
        */
        // attach the toggle behavior to the h3 tag
        $('h3', f_content.parent()).click(function(){
           // toggle the content
           $(f_content).slideToggle();
       });
   }
});
});
