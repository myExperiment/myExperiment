// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

function redirectToAddToPack() {
  var url = $("add_to_pack_selection").value;
  location.href = url;
}

function checkAll(checkboxes){
  for (var i=0; i<checkboxes.length; i++){
    checkbox = document.getElementById(checkboxes[i]);
    checkbox.checked="checked";
  }
}

function uncheckAll(checkboxes){
  for (var i=0; i<checkboxes.length; i++){
    checkbox = document.getElementById(checkboxes[i]);
    checkbox.checked="";
  }
}

