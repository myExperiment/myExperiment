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

document.observe("dom:loaded", function() {
  $(document).observe('click', function(e) {
    $('user_menu').hide();
    $('expand_user_menu').show();
    $('collapse_user_menu').hide();
  });


  $('user_menu_button').observe('click',function(e) {
    e.stopPropagation();
    $('user_menu').toggle();
    $('expand_user_menu').toggle();
    $('collapse_user_menu').toggle();
  });

  $('user_menu').observe('click',function(e) {
    e.stopPropagation();
  });
});