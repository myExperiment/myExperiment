//:success => "$('tag_list').value=''; new Effect.Highlight('tags_inner_box', { duration: 1.5 });",
// :loading => "Element.show('addtag_indicator')",
//       	   	       :complete => "Element.hide('addtag_indicator')")
//page.replace_html "mini_nav_tag_link", "(#{unique_tag_count})"
//page.replace_html "tags_box_header_tag_count_span", "(#{unique_tag_count})"
//page.replace_html "tags_inner_box",

// Handle the dynamic submission of tags

$j(document).ready(function(){

    // Finn: Not sure what this does...
    $j("#tag-form").on('ajax:before', function (event) {
        $j('#addtag_indicator').show();
    });

    $j("#tag-form").on('ajax:success', function (event, data, status, xhr) {
        $j('#tag_list').val('');
        new Effect.Highlight('tags_inner_box', { duration: 1.5 });
        $j('#tags_inner_box').html(data);
    });

    $j("#tag-form").on('ajax:error', function (event, xhr, status, error) {
        alert("An error occur whilst submitting your tag.");
        console.log("ERROR: " + error);
    });

    $j("#tag-form").on('ajax:complete', function (event, xhr, status) {
        $j('#addtag_indicator').hide();
    });
});
