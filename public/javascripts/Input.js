var Input = {};

Input.remove_input = function (input) {
	if ($("#scripts").children().length > 1) {
		$(input).parent().parent().hide('fast', function () {
			$(this).remove();
		});
	}
}

Input.add_input = function (input) {
	var new_input = $(input).parent().parent().clone().css('display', 'none');
	new_input.prependTo("#scripts");
	new_input.find(".script_text").show();
	new_input.find(".script_url").hide();
	new_input.show('fast');
	new_input.find(".script_text").attr('value', '');
	new_input.find(".script_url").attr('value', '');
	new_input.focus();
	
	$(input).hide();
	$(input).parent().find(".remove_button").show();
}

Input.change_input = function (input) {
	if (input.value == 'text') {
		$(input).parent().parent().find(".script_url").hide('fast');
		$(input).parent().parent().find(".script_text").show('fast');
		$(input).parent().parent().find(".script_text").focus();
	}
	else {
		$(input).parent().parent().find(".script_text").hide('fast');
		$(input).parent().parent().find(".script_url").show('fast');
		$(input).parent().parent().find(".script_url").focus();
	}
}

Input.prepare_submit = function() {
	var total_script = 0;
	var total_url = 0;
	$('.script_text').each(function (i) {
		if (this.value.length) {
			$('<input />', {type:'hidden', value: this.value, name:"script_"+String(total_script++)}).appendTo('#script_form');
		}
	});
	$('.script_url').each(function (i) {
		if (this.value.length) {
			$('<input />', {type:'hidden', value: this.value, name:"url_"+String(total_url++)}).appendTo('#script_form');
		}
	});
	$('.script_format').each(function (i) {
		$('<input />', {type:'hidden', value: $(this).text(), name:"script_"+String(total_script++)}).appendTo('#script_form');
	});
}

