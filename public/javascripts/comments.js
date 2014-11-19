$j(document).ready(function(){

    // Finn: Not sure what this does...
    $j("#comment-form").on('ajax:before', function (event,data,status,xhr) {
        for (instance in CKEDITOR.instances) {
            CKEDITOR.instances[instance].updateElement()
        }
        $j('#addcomment_indicator').show();
    });

    $j("#comment-form").on('ajax:success', function (event,data,status,xhr) {
        $j('#comments').html(data);
        new Effect.Highlight('comments', { duration: 1.5 });
        $j('#comment').innerHTML = '';
        CKEDITOR.instances.comment_comment.setData('');
    });

    $j("#comment-form").on('ajax:failure', function (event,data,status,xhr) {
        alert("An error occur whilst submitting your comment.");
        console.log("ERROR: " + data);
    });

    $j("#comment-form").on('ajax:complete', function (event,data,status,xhr) {
        $j('#addcomment_indicator').hide();
    });

    // The following statement makes sure that the handler is bound to new comments that are added even after the page
    //   is loaded.
    $j('#commentsBox').on('ajax:success', '.delete-comment', function (event,data,status,xhr) {
        new Effect.Highlight('comments', { duration: 1.5 });
        $j('#comments').html(data);
    });
});
