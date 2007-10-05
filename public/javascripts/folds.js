// fold.js

function foldUpdate(el) {

  var children = getPaneTitleDiv(el).childNodes;

  var img = "/images/folds/fold.png";

  if (getPaneBodyDiv(el).style.display == 'none')
    img = "/images/folds/unfold.png";

  children[0].innerHTML =
    '<img src="' + img + '"' + 
    ' onclick="javascript:foldToggle(this);">&nbsp;&nbsp;';
}

function foldToggle(el) {

  function parent(el) {

    if (el.parentElement != undefined)
      return el.parentElement;

    return el.parentNode;
  }

  var pane = parent(parent(parent(el)));

  var style = getPaneBodyDiv(pane).style;

  if (style.display == 'none') {
    style.display = 'block';
  } else {
    style.display = 'none';
  }

  foldUpdate(pane);
}

function getTags(el, tag) {

  var result = new Array();

  for (var i = 0; i < el.childNodes.length; i++) {
    if (el.childNodes[i].tagName == tag) {
      result.push(el.childNodes[i]);
    }
  }
}

function getNthTag(el, tag, index) {

  var count = 0;

  for (var i = 0; i < el.childNodes.length; i++) {
    if (el.childNodes[i].tagName == tag) {
      if (count++ == index) {
        return el.childNodes[i];
      }
    }
  }
}

function getPaneTitleDiv(el) {
  return getNthTag(el, 'DIV', 0);
}

function getPaneBodyDiv(el) {
  return getNthTag(el, 'DIV', 1);
}

function initialiseFolds() {

  var divs = document.getElementsByTagName('DIV');

  for (var i = 0; i < divs.length; i++) {

    var div = divs[i];

    if (div.className == 'fold') {

      var paneCommands = document.createElement('SPAN');
      var title        = getPaneTitleDiv(div);

      title.insertBefore(paneCommands, title.firstChild);

      foldUpdate(div);
    }
  }
}

initialiseFolds();

