// select_book.js
//
// Requires the html element: <select id='book' data-url='URL'>
// Assumes that the server recognizes the URL: URL?book=NAME

/*global YUI */
/*global window */

YUI().use('node', function(Y) {
	function select_book(node) {
//		var opt = sel.down('option', sel.selectedIndex);
//		opt = opt.value;
		var url = node._node.getAttribute('data-url');
		var sel = node._node.value;
		window.location = url + "?book=" + sel;

	}

    Y.on("change", function(e) {
        select_book(e.target);
    }, "#book");
});
