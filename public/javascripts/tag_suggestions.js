// tag_suggestions.js

var suggestions = new Array();
var tagsToAdd   = new Array();

function commaList(list) {

  result = "";

  for (i = 0; i < list.length; i++) {
    result += "<em>" + list[i] + "</em>";

    if (i < (list.length - 2)) {
      result += ", ";
    } else if (i < (list.length - 1)) {
      result += " and ";
    }
  }

  return result;
}

function defineTag(name) {
  suggestions.push(name);
}

function addTag(name) {

  if (tagsToAdd.indexOf(name) == -1) {

    tagsToAdd.push(name);
    updateTagViews();
  }
}

function removeTag(name) {

  tagsToAdd.splice(tagsToAdd.indexOf(name), 1);
  updateTagViews();
}

function updateTagViews() {

  separator  = ' <span style="color: #999999;">|</span> ';
  markup     = "";
  summary    = "";

  if (suggestions.length == 0) {

    markup = "There are no tag suggestions!";

  } else {

    for (i = 0; i < suggestions.length; i++) {

      tag = suggestions[i];
      cl  = 'unselected_tag_suggestion';
      fun = 'addTag';

      if (tagsToAdd.indexOf(tag) != -1) {
        cl  = 'selected_tag_suggestion';
        fun = 'removeTag';
      }
      
      markup += '<a class="' + cl + '" href="" onclick="javascript:' + fun +
        '(\'' + tag + '\'); return false;">' + tag + '</a>';

      if (i != (suggestions.length - 1))
        markup += separator;
    }
  }

  if (tagsToAdd.length == 0) {
    summary = "<p>You have no tags to add to this workflow.</p>";
  } else {
    summary = "<p>You are about tag this workflow with: " + commaList(tagsToAdd.sort()) + ".";
  }

  document.getElementById("suggestions").innerHTML  = markup;
  document.getElementById("tag_list").value         = tagsToAdd.join(", ");
  document.getElementById("summary-text").innerHTML = summary;
}

