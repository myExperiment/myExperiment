// This requires the Prototype JS library 1.5.0 to work

var field_counter = 1;

var stop_timer = false;

function update_inputs_states(input_name, input_type_selected) {
	if (input_type_selected == 'single')
  {
      document.getElementById(input_name + '_single_input_box').style.display = 'block';
      document.getElementById(input_name + '_list_input_box').style.display = 'none';
      document.getElementById(input_name + '_file_input_box').style.display = 'none';
  }
  else if (input_type_selected == 'list')
  {
      document.getElementById(input_name + '_single_input_box').style.display = 'none';
      document.getElementById(input_name + '_list_input_box').style.display = 'block';
      document.getElementById(input_name + '_file_input_box').style.display = 'none';
  }
  else if (input_type_selected == 'file')
  {
      document.getElementById(input_name + '_single_input_box').style.display = 'none';
      document.getElementById(input_name + '_list_input_box').style.display = 'none';
      document.getElementById(input_name + '_file_input_box').style.display = 'block';
  }
  else
  {
      document.getElementById(input_name + '_single_input_box').style.display = 'none';
      document.getElementById(input_name + '_list_input_box').style.display = 'none';
      document.getElementById(input_name + '_file_input_box').style.display = 'none';
  }
}

function add_input_field(input_name, parent_id) {
	field_counter++;
	
	p_id = input_name + '_p_' + field_counter;
	
	input_id = input_name + '_list_input[' + field_counter + ']';
	
	var html = '<p id="' + p_id + '">'
	html += '<input id="' + input_id + '" type="text" size="90" name="' + input_id + '"/>';
	html += '&nbsp;&nbsp;&nbsp;<small>[<a href="" onclick="javascript:Element.remove(\'' + p_id + '\'); return false;">delete</a>]</small>';
	
	new Insertion.Bottom(parent_id, html);
}

function update_op_list(id) {
	setTimeout(function() {
		var op_list = document.getElementById("op_list");
	
		for (var i = 0; i < op_list.childNodes.length; i++) {
	    if (op_list.childNodes[i].id == id) {
				op_list.childNodes[i].className = 'selected';
			}
			else {
				op_list.childNodes[i].className = '';
			}
	  }
	}, 100);
}
