/*global YUI */
/*global dialogMaker */
/*global lines */

YUI().use('node', 'event-delegate', 'event-key', 'event-custom', function(Y) {

	function find(dlg) {
		var data = dlg.getAllData();
		dlg.setFlash("Finding " + data.find, false);

		var found = false;
		for (var i = 0; i < lines.length; i++) {
			var text = lines[i].word;
			if (text.indexOf(data.find) >= 0) {
				Y.Global.fire('changeLine:highlight', i, data.find);
				found = true;
				break;
			}
		}
		if (found) {
			dlg.cancel();
		} else {
			dlg.setFlash("Text not found on page", true);
		}
	}

	function find_dlg() {

		var body = { layout: [
				[ { type: 'label', klass: 'dlg_find_label', text: 'Find:' }, { type: 'input', klass: 'dlg_find', name: 'find', focus: true }]
			]
		};

		dialogMaker.dialog({
			config: { id: 'find_dlg', action: "", div: '', align: ".find_button", lineClass: 'dlg_find_line' },
			header: { title: 'Find Text on Page' },
			body: body,
			footer: {
				buttons: [
					{ label: 'ok', action: find, def: true },
					{ label: 'cancel', action: 'cancel' }
				]
			}
		});
	}

	var kH = 72;

    Y.on("click", function(e) {
		find_dlg();
    }, ".find_button");

	Y.on('key', function(e) {
		e.halt();
		find_dlg();
	}, 'body', 'down:'+kH+'+shift+ctrl', Y);

});

