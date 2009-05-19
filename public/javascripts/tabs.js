// tabs.js

var tabImagesRoot = '/images/tabs/';

function parent_el(el) {

  if (el.parentElement != undefined)
    return el.parentElement;

  return el.parentNode;
}

function addEvent(type, element, func) {
  if (element.addEventListener){
    element.addEventListener(type, func, false); 
  } else if (element.attachEvent){
    element.attachEvent('on' + type, func);
  }
}

function deSlash(str) {
  return str.replace(/^\//, '');
}

function selectTab(tabsDiv, t) {

  var html = '<table cellspacing=0 cellpadding=0><tr>';

  if (tabsDiv.titles.length > 0)
    html += '<td><img src="' + tabImagesRoot + '/tab_separator.png"></td>';

  for (var i = 0; i < tabsDiv.titles.length; i++) {

    if (i == t) {

      tabsDiv.panes[i].style.display = 'block';

      html += '<td class="tabSelIMG"><img src="' + tabImagesRoot;
      html += '/selected_tab_start.png"></td>';
      html += '<td class="tabSelected"><span onmousedown="';
      html += 'javascript:return false;">';
      html += tabsDiv.titles[i];
      html += '</span></td>';
      html += '<td class="tabSelIMG"><img src="' + tabImagesRoot;
      html += '/selected_tab_end.png"></td>';

    } else {

      tabsDiv.panes[i].style.display = 'none';

      html += '<td class="tabUnselIMG"><img src="' + tabImagesRoot;
      html += '/unselected_tab_start.png"></td>';
      html += '<td class="tabUnselected"><span onmousedown="';
      html += 'javascript:selectTab(parent_el(parent_el(parent_el(parent_el(parent_el(this))))), ' + i +
          '); return false;">';
      html += tabsDiv.titles[i];
      html += '</span></td>';
      html += '<td class="tabUnselIMG"><img src="' + tabImagesRoot;
      html += '/unselected_tab_end.png"></td>';
    }

    html += '<td><img src="' + tabImagesRoot + '/tab_separator.png"></td>';
  }

  html += '</td></tr></table>';

  tabsDiv.innerHTML = html;
}

function showFragment(fragment, scroll) {

  var root = document.all ? "BODY" : "HTML";
  var el   = document.getElementById(fragment);

  if (el != undefined) {

    for (; el.tagName != root; el = parent_el(el)) {
      if (el.className == 'tabContainer') {
        selectTab(el.tabsDiv, el.tabsIndex);
      }
    }
  }

  if (scroll) {
    document.getElementById(fragment).scrollIntoView(false);
  }
}

function initialiseTabs() {

  function getElementByClassName(el, cl) {
    for (var i = 0; i < el.childNodes.length; i++) {
      if (el.childNodes[i].className == cl) {
        return el.childNodes[i];
      }
    }
  }

  function getTabTitleDiv(el) {
    return getElementByClassName(el, 'tabTitle');
  }

  function getTabContentDiv(el) {
    return getElementByClassName(el, 'tabContent');
  }

  var divs = document.getElementsByTagName('DIV');

  for (var i = 0; i < divs.length; i++) {

    var tabsDiv = divs[i];

    if (tabsDiv.className == 'tabsContainer') {

      tabsDiv.titles = new Array();
      tabsDiv.panes  = new Array();

      var sibling = tabsDiv.nextSibling;
      var count   = 0;

      while (sibling != null) {

        if (sibling.className == 'tabsContainer')
          break;

        if (sibling.className == 'tabContainer') {

          var titleDiv = getTabTitleDiv(sibling);

          titleDiv.style.display = 'none';

          tabsDiv.titles.push(titleDiv.innerHTML);
          tabsDiv.panes.push(sibling);

          sibling.tabsDiv   = tabsDiv;
          sibling.tabsIndex = count++;
        }

        sibling = sibling.nextSibling;
      }

      selectTab(tabsDiv, 0);
    }
  }

  if (window.location.hash.length > 0) {
    showFragment(window.location.hash.substring(1));
  }

  var anchors = document.getElementsByTagName('A');
  var loc     = window.location;

  for (var i = 0; i < anchors.length; i++) {

    if ((anchors[i].href) &&
        (anchors[i].hash != undefined) &&
        (anchors[i].protocol == loc.protocol) &&
        (anchors[i].hostname == loc.hostname) &&
        (anchors[i].search == loc.search) &&
        (deSlash(anchors[i].pathname) == deSlash(loc.pathname))) {

      addEvent('click', anchors[i], hashClicked);
    }
  }
}

function hashClicked(evt) {

  var el = evt.target ? evt.target : event.srcElement;

  showFragment(el.hash.substring(1), true);
  return false;
}

addEvent('load', window, initialiseTabs);

