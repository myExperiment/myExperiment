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
