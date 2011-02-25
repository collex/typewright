/*global YUI */
/*extern serverNotify */

// This just sends a notification to the server and doesn't need a response.
var serverNotify = function(url, params) {
	YUI().use('io', 'querystring-stringify', function(Y) {
		function onFailure(num, resp) {
			if (resp.status === 500)
				alert("Server error: see log for details.");
			else
				alert(resp.responseText);
		}
		// The default call of stringify doesn't create the array parameters in the right format for ruby, so we call it explicitly here.
		var str = Y.QueryString.stringify( params, { arrayKey: true } );
		Y.io(url, { method: 'POST', data: str, on: { failure: onFailure } });
	});
};

