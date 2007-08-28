// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

function focus_sharing(value) {
  if (value == 1) {
    // enable check boxes
    document.getElementById('friends').disabled = false; 
    document.getElementById('sharing_users').disabled = false; 
    document.getElementById('sharing_projects').disabled = false;
  } else {
    // disable check boxes
    document.getElementById('friends').disabled = true; 
    document.getElementById('sharing_users').disabled = true; 
    document.getElementById('sharing_projects').disabled = true;
  }
}
