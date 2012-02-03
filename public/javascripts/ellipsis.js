// ellipsis.js

function parentEl(el) {
  return el.parentElement ? el.parentElement : el.parentNode;
}

function truncate_span(span) {

  var targetWidth = parentEl(span).offsetWidth;

  if (span.offsetWidth <= targetWidth)
    return;

  var text = span.innerHTML;
  var pos  = text.length;

  while ((span.offsetWidth > targetWidth) && (pos > 0)) {
    pos--;
    span.innerHTML = text.substring(0, pos) + "&hellip; "
  }
}

function truncate_spans() {

  var spans = document.getElementsByTagName('SPAN');

  for (var i = 0; i < spans.length; i++) {
    var span = spans[i];

    if (span.className == 'truncate') {
      truncate_span(span);
    }
  }
}

