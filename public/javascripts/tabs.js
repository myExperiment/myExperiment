// tabs.js

tabTitles = new Array();
tabPanes  = new Array();

function selectTab(t) {

  var html = '<table cellspacing=0 cellpadding=0><tr>';

  if (tabTitles.length > 0)
    html += '<td><img src="/images/tabs/tab_separator.png"></td>';

  for (var i = 0; i < tabTitles.length; i++) {

    if (i == t) {

      tabPanes[i].style.display = 'block';

      html += '<td><img src="/images/tabs/selected_tab_start.png"></td>';
      html += '<td class="tabSelected"><span onmousedown="';
      html += 'javascript:return false;">';
      html += tabTitles[i];
      html += '</span></td>';
      html += '<td><img src="/images/tabs/selected_tab_end.png"></td>';

    } else {

      tabPanes[i].style.display = 'none';

      html += '<td><img src="/images/tabs/unselected_tab_start.png"></td>';
      html += '<td class="tabUnselected"><span onmousedown="';
      html += 'javascript:selectTab(' + i + '); return false;">';
      html += tabTitles[i];
      html += '</span></td>';
      html += '<td><img src="/images/tabs/unselected_tab_end.png"></td>';
    }

    html += '<td><img src="/images/tabs/tab_separator.png"></td>';
  }

  html += '</td></tr></table>';

  document.getElementById('tabsContainer').innerHTML = html;
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

  if (document.getElementById('tabsContainer') == undefined)
    return;

  var divs = document.getElementsByTagName('DIV');

  for (var i = 0; i < divs.length; i++) {

    var div = divs[i];

    if (div.className == 'tabContainer') {

      var titleDiv = getTabTitleDiv(div);

      titleDiv.style.display = 'none';

      tabTitles.push(titleDiv.innerHTML);
      tabPanes.push(div);
    }
  }

  selectTab(0);
}

initialiseTabs();

