// Handle the [report] links next to comments and messages.

$j(document).ready(function(){

    $j(".report-link").on('ajax:before', function (event) {
        // Disable link
        $j(this).bind('click', false).html("reporting...");
    });

    $j(".report-link").on('ajax:success', function (event, data, status, xhr) {
        $j(this).replaceWith("reported");
        alert("Your report has been submitted.");
    });

    $j(".report-link").on('ajax:error', function (event, xhr, status, error) {
        $j(this).unbind('click', false).html('report');
        alert("An error occur whilst submitting your report.");
        console.log("ERROR: " + error);
    });

});
