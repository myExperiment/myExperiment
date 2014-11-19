$j(document).ready(function(){

    // Finn: Not sure what this does...
    $j("#comment-form").on('ajax:before', function (event) {
        for (instance in CKEDITOR.instances) {
            CKEDITOR.instances[instance].updateElement()
        }
        $j('#addcomment_indicator').show();
    });

    $j("#comment-form").on('ajax:success', function (event, data, status, xhr) {
        $j('#comments').html(data);
        new Effect.Highlight('comments', { duration: 1.5 });
        $j('#comment').innerHTML = '';
        CKEDITOR.instances.comment_comment.setData('');
    });

    $j("#comment-form").on('ajax:error', function (event, xhr, status, error) {
        alert("An error occur whilst submitting your comment.");
        console.log("ERROR: " + error);
    });

    $j("#comment-form").on('ajax:complete', function (event, xhr, status) {
        $j('#addcomment_indicator').hide();
    });

    // The following statement makes sure that the handler is bound to new comments that are added even after the page
    //   is loaded.
    $j('#commentsBox').on('ajax:success', '.delete-comment', function (event, data, status, xhr) {
        new Effect.Highlight('comments', { duration: 1.5 });
        $j('#comments').html(data);
    });
});
