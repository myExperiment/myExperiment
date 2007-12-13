// AJAX interface

function obtainXHR() {

  if (XMLHttpRequest){
    return new XMLHttpRequest();
  } else {
    return new ActiveXObject('MSXML2.XMLHTTP.3.0');
  }
}

function getText(element) {

  if (element == undefined)
    return 'ERROR';

  if (element.firstChild != null)
    return element.firstChild.nodeValue;

  return '';
}

function showError(doc) {

  var errors = doc.getElementsByTagName('error');
  var str = "Errors:\n\n";

  for (var i = 0; i < errors.length; i++) {
    str += '  * ' + getText(errors.item(i)) + '\n';
  }

  alert(str);
}

function getDocumentSync(command, url, data) {

  var xhr = obtainXHR();

  document.getElementById('custom-method').value = command;
  document.getElementById('custom-uri').value = url;

  xhr.open(command, url, false);
  xhr.setRequestHeader('Accept', 'application/xml');
  xhr.setRequestHeader('Content-Type', 'application/xml');
  xhr.send(data);

  if (data != null)
    document.getElementById('input').value = data;

  document.getElementById('output').value = xhr.responseText;

  if (xhr.responseXML.documentElement.nodeName == 'errors')
    showError(xhr.responseXML);

  return xhr.responseXML;
}

function input() {
  return document.getElementById('input').value;
}

// User functions

function userID() {
  return document.getElementById('user-id').value;
}

function newUser() {
  getDocumentSync('POST', '/users', input());
}

function listUsers() {
  getDocumentSync('GET', '/users', null);
}

function getUser() {
  getDocumentSync('GET', '/users/' + userID(), input());
}

function updateUser() {
  getDocumentSync('PUT', '/users/' + userID(), input()); 
}

function deleteUser() {
  getDocumentSync('DELETE', '/users/' + userID(), null); 
}

// Profile functions

function profileID() {
  return document.getElementById('profile-id').value;
}

function newProfile() {
  getDocumentSync('POST', '/profiles', input());
}

function listProfiles() {
  getDocumentSync('GET', '/profiles', null);
}

function getProfile() {
  getDocumentSync('GET', '/profiles/' + profileID(), null);
}

function updateProfile() {
  getDocumentSync('PUT', '/profiles/' + profileID(), input());
}

function deleteProfile() {
  getDocumentSync('DELETE', '/profiles/' + profileID(), null);
}

// Network functions

function groupID() {
  return document.getElementById('group-id').value;
}

function newNetwork() {
  getDocumentSync('POST', '/groups', input());
}

function listNetworks() {
  getDocumentSync('GET', '/groups', null);
}

function getNetwork() {
  getDocumentSync('GET', '/groups/' + groupID(), null);
}

function updateNetwork() {
  getDocumentSync('PUT', '/groups/' + groupID(), input());
}

function deleteNetwork() {
  getDocumentSync('DELETE', '/groups/' + groupID(), null);
}

// Message functions

function messageID() {
  return document.getElementById('message-id').value;
}

function newMessage() {
  getDocumentSync('POST', '/messages', input());
}

function listMessages() {
  getDocumentSync('GET', '/messages', null);
}

function getMessage() {
  getDocumentSync('GET', '/messages/' + messageID(), null);
}

function updateMessage() {
  getDocumentSync('PUT', '/messages/' + messageID(), input());
}

function deleteMessage() {
  getDocumentSync('DELETE', '/messages/' + messageID(), null);
}

// Temporary authorisation functions

function authID() {
  return document.getElementById('auth-id').value;
}

function login() {
  getDocumentSync('POST', '/auth/login',
      '<?xml version="1.0"?>\n<id>' + authID() + '</id>');
}

function logout() {
  getDocumentSync('POST', '/auth/logout',
      '<?xml version="1.0?>\n<id>' + authID() + '</id>');
}

// Custom function

function doCustom() {

  var method = document.getElementById('custom-method').value;
  var uri    = document.getElementById('custom-uri').value;
  var data   = null;

  if ((method == 'POST') || (method == 'PUT'))
    data = input();

  getDocumentSync(method, uri, data);
}

function pageLoaded() {
}

