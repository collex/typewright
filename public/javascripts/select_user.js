// select_user.js
//
// Requires the html element: <select id='user' >

/*global YUI */

YUI().use('node', function(Y) {
	function select_user(node) {
		var form = Y.one('#set_user');
		form.submit();
	}

    Y.on("change", function(e) {
        select_user(e.target);
    }, "#post_user");
});
