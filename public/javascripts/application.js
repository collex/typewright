$(document).ready(function() {
    $("#button").bind("click", function() {
        /* Generating unique id */
        var rand = Math.random().toString().split(".")[1];
        var input = '<input type="file" class="'+rand+'" />'
        $(this).before('<br/>' + input );
    });
    /* Pushing the first input to the DOM
    */
    $("#button").trigger("click");
});