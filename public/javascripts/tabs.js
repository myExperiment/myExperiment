// tabs.js

var tabImagesRoot = '/images/tabs/';

function parent(el) {

  if (el.parentElement != undefined)
    return el.parentElement;

  return el.parentNode;
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
      html += 'javascript:selectTab(parent(parent(parent(parent(parent(this))))), ' + i +
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

    var hash = window.location.hash.substring(1);
    var root = document.all ? "BODY" : "HTML";
    var el   = document.getElementById(hash);

    if (el != undefined) {

      for (; el.tagName != root; el = parent(el)) {
        if (el.className == 'tabContainer') {
          selectTab(el.tabsDiv, el.tabsIndex);
        }
      }
    }
  }
}

initialiseTabs();

