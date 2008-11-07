// tag_suggestions.js

var suggestions = new Array();
var tagsToAdd   = new Array();

function updateAddBox() {
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

function addingTag(name) {
  alert("Adding tag: " + name);
}

function tagSuccess(name) {
  document.getElementById("tag_" + name).innerHTML = "Tag \""+ name + "\" added.";
  alert("Tag success: " + name);
}

function defineTag(name) {
  suggestions.push(name);
}

function updateTagViews() {

  visibleSuggestions = new Array();

  for (var i = 0; i < suggestions.length; i++) {
    s = suggestions[i];
    if (tagsToAdd.indexOf(s) == -1) {
      visibleSuggestions.push(s);
    }
  }

  var separator = ' <span style="color: #999999;">|</span> ';

  // visible suggestions

  var markup = "";

  if (visibleSuggestions.length == 0) {

    markup = "There are no remaining tag suggestions!";
  } else {

    for (var i = 0; i < visibleSuggestions.length; i++) {

      markup += '<a href="" onclick="javascript:addTag(\'' + visibleSuggestions[i] +
        '\'); return false;">' + visibleSuggestions[i] + '</a>';

      if (i != (visibleSuggestions.length - 1))
        markup += separator;
    }
  }

  document.getElementById("suggestions").innerHTML = markup;

  // selected tags

  markup = "";

  if (tagsToAdd.length == 0) {

    markup = "You have not selected any tag suggestions (click on tags below to add).";

  } else {

    for (var i = 0; i < tagsToAdd.length; i++) {

      markup += '<a href="" onclick="javascript:removeTag(\'' + tagsToAdd[i] +
        '\'); return false;">' + tagsToAdd[i] + '</a>';

      if (i != (tagsToAdd.length - 1))
        markup += separator;
    }
  }

  document.getElementById("to-add").innerHTML = markup;
}

