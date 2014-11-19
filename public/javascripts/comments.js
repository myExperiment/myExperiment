$j(document).ready(function(){

    // Finn: Not sure what this does...
    $j("#comment-form").bind('ajax:before', function (event,data,status,xhr) {
        for (instance in CKEDITOR.instances) {
            CKEDITOR.instances[instance].updateElement()
        }
        $j('#addcomment_indicator').show();
    });

    $j("#comment-form").bind('ajax:success', function (event,data,status,xhr) {
        $j('#comments').html(data);
        new Effect.Highlight('comments', { duration: 1.5 });
        $j('#comment').innerHTML = '';
        CKEDITOR.instances.comment_comment.setData('');
    });

    $j("#comment-form").bind('ajax:failure', function (event,data,status,xhr) {
        alert("An error occur whilst submitting your comment.");
        console.log("ERROR: " + data);
    });

    $j("#comment-form").bind('ajax:complete', function (event,data,status,xhr) {
        $j('#addcomment_indicator').hide();
    });

});
