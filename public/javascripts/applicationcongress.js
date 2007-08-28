// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

var myWidth;
var myHeight;
function openSection(value) {
	document.getElementById(value + "Section").style.display = "block";
	document.getElementById(value + "Close").style.display = "inline";
	document.getElementById(value + "Open").style.display = "none";
}

function closeSection(value) {
	document.getElementById(value + "Section").style.display = "none";
    document.getElementById(value + "Close").style.display = "none";
    document.getElementById(value + "Open").style.display = "inline";
}

function WindowSize()
{
     if( typeof( window.innerWidth ) == 'number' ) {
          //Non-IE
          myWidth = window.innerWidth;
          myHeight = window.innerHeight;
     }
     else if( document.documentElement &&
            (document.documentElement.clientWidth || document.documentElement.clientHeight ) ) {
          //IE 6+ in 'standards compliant mode'
          myWidth = document.documentElement.clientWidth;
          myHeight = document.documentElement.clientHeight;
     }
     else if( document.body && ( document.body.clientWidth || document.body.clientHeight ) ) {
          //IE 4 compatible
          myWidth = document.body.clientWidth;
          myHeight = document.body.clientHeight;
     }
}
function GetWindowHeight () {
    WindowSize();
     return myHeight;
}
function GetWindowWidth () {
    WindowSize();
     return myWidth;
}
function AutoResize() {
     var width, height;
     width = GetWindowWidth();
     widthmt=width-58
     height = GetWindowHeight();
		height = height - $('typebox').clientHeight - $('header').clientHeight - 6;
		$('conversation').style.height = height + "px";
		$('userlist').style.height = height + "px";
	//	$('topicfield').style.width = widthmt + "px"; 
}
function submitenter(e){
	if (e.shiftKey && e.keyCode == 13){
		
	}
	else if (e.keyCode == 13 ){
		document.forms.sayit.onsubmit()
		
	}
}