// osp.js

function trimSpaces(str) {

  while ((str.length > 0) && (str.charAt(0) == ' '))
    str = str.substring(1);

  while ((str.length > 0) && (str.charAt(str.length - 1) == ' '))
    str = str.substring(0, str.length - 1);

  return str;
}

// tags

var tags = new Array();

function updateTagList() {

  var markup = '';

  if (tags.length == 0) {

    markup = '<i>None</i>';

  } else {

    for (var i = 0; i < tags.length; i++)
      markup += tags[i] +
        '&nbsp;&nbsp;&nbsp;<small>[<a href="" onclick="javascript:deleteTag(\'' + tags[i].replace("'", "\\'") +
        '\'); return false;">delete</a>]</small><br />';
  }

  document.getElementById('tags_current_list').innerHTML = markup;

  // also update the web form

  var tag_list = '';

  for (var i = 0; i < tags.length; i++) {
    tag_list += tags[i];

    if (i != (tags.length - 1))
      tag_list += ',';
  }

  document.getElementById('tag_list').value = tag_list;
}

function addTag(str) {

  var newTags = str.split(',');
  
  for (var i = 0; i < newTags.length; i++) {

    var tag = trimSpaces(newTags[i]);

    tag = tag.replace('"', '');

    if (tag.length == 0)
      continue;

    if (tags.indexOf(tag) != -1)
      continue;

    tags.push(tag);
  }

  updateTagList();
}

function deleteTag(tag) {

  var i = tags.indexOf(tag);

  if (i == -1)
    return;

  tags.splice(i, 1);
  updateTagList();
}

// end tags

function toggle_visibility(id) {
   var e = document.getElementById(id);
   if(e.style.display == 'block')
      e.style.display = 'none';
   else
      e.style.display = 'block';
}

// credit and attribution

var credit_me = true;
var credit_friends = new Object();
var credit_otherusers = new Object();
var credit_groups = new Object();

function updateAuthorList() {
	
	var markup = '';
	
	if (credit_me)
	{
		markup += 'Me&nbsp;&nbsp;&nbsp;<small>[<a href="" t="me" onclick="javascript:deleteAuthor(this); ' +
    		'return false;">delete</a>]</small><br/>';
	}
	
	for (var key in credit_friends)
	{
		markup += 'Friend: ' + credit_friends[key] + '&nbsp;&nbsp;&nbsp;<small>[<a href="" t="friend" key="' + key + '" onclick="javascript:deleteAuthor(this); ' +
    		'return false;">delete</a>]</small><br/>';
	}
	
	for (var key in credit_otherusers)
	{
		markup += 'Other user: ' + credit_otherusers[key] + '&nbsp;&nbsp;&nbsp;<small>[<a href="" t="otheruser" key="' + key + '" onclick="javascript:deleteAuthor(this); ' +
    		'return false;">delete</a>]</small><br/>';
	}
	
	for (var key in credit_groups)
	{
		markup += 'Group: ' + credit_groups[key] + '&nbsp;&nbsp;&nbsp;<small>[<a href="" t="group" key="' + key + '" onclick="javascript:deleteAuthor(this); ' +
    		'return false;">delete</a>]</small><br/>';
	}
	
	if (markup == '')
	{
		markup = '<i>None</i>';
	}
	
	document.getElementById('authors_list').innerHTML = markup;
	
	// Also update web form (the hidden input fields)
	
	// Me
	if (credit_me)
	{
		document.getElementById('credits_me').value = "true";
	}
	
	// Friends
	var friends_list;
	
	for (var key in credit_friends)
	{
		friends_list += key + ',';
	} 
	
	document.getElementById('credits_friends').value = friends_list;
	
	// Other users
	var otherusers_list;
	
	for (var key in otherusers_list)
	{
		otherusers_list += key + ',';
	} 
	
	document.getElementById('credits_otherusers').value = otherusers_list;
	
	// Groups
	var groups_list;
	
	for (var key in groups_list)
	{
		groups_list += key + ',';
	} 
	
	document.getElementById('credits_groups').value = groups_list;
}

function addAuthor() {
    
	// Me
    if (document.getElementById('author_option_1').checked)
	{
		credit_me = true;
	}
	// One of my Friends 
	else if (document.getElementById('author_option_2').checked)
	{
		var x = document.getElementById('author_friends_dropdown');
		
		if (x.options.length > 0)
		{
			var y = x.options[x.selectedIndex];
	     	credit_friends[y.value] = y.text;
		}
	}
	// A user on myExperiment who is not a Friend.
	else if (document.getElementById('author_option_3').checked)
	{
		var x = document.getElementById('author_otheruser_dropdown');
		
		if (x.options.length > 0)
		{
			var y = x.options[x.selectedIndex];
	     	credit_otherusers[y.value] = y.text;
		}
	}
	// A myExperiment Group
	else if (document.getElementById('author_option_4').checked)
	{
		var x = document.getElementById('author_networks_dropdown');
		
		if (x.options.length > 0)
		{
			var y = x.options[x.selectedIndex];
	     	credit_groups[y.value] = y.text;
		}
	}
	
	updateAuthorList();
}

function deleteAuthor(obj) {
	if (obj.t)
	{
		if (obj.t == 'me')
		{
			credit_me = false;
		}
		else if (obj.t == 'friend')
		{
			delete credit_friends[obj.key];
		}
		else if (obj.t == 'otheruser')
		{
			delete credit_otherusers[obj.key];
		}
		else if (obj.t == 'group')
		{
			delete credit_groups[obj.key];
		}
	}
	
	updateAuthorList();
}

function update_author(parentId) {

    if (parentId == 'author_option_2')
    {
        document.getElementById('author_friends_box').style.display = 'block';
        document.getElementById('author_otheruser_box').style.display = 'none';
        document.getElementById('author_networks_box').style.display = 'none';
    }
    else if (parentId == 'author_option_3')
    {
        document.getElementById('author_friends_box').style.display = 'none';
        document.getElementById('author_otheruser_box').style.display = 'block';
        document.getElementById('author_networks_box').style.display = 'none';
    }
    else if (parentId == 'author_option_4')
    {
        document.getElementById('author_friends_box').style.display = 'none';
        document.getElementById('author_otheruser_box').style.display = 'none';
        document.getElementById('author_networks_box').style.display = 'block';
    }
    else
    {
        document.getElementById('author_friends_box').style.display = 'none';
        document.getElementById('author_otheruser_box').style.display = 'none';
        document.getElementById('author_networks_box').style.display = 'none';
    }
}

var attributions = new Object();

function updateAttributionsList() {
	
}

function addAttribution() {
    
}

function deleteAttribution() {
	
}

// end credit and attribution

function toggle_copy_inherit(obj) {
    var f = document.getElementById('copy_inherit_sharing_box');
    
    if(obj.oldText)
    {
        f.style.display = 'none';
        obj.innerHTML = obj.oldText;
        obj.oldText = null;
    } 
    else 
    {
        f.style.display = 'block';
        obj.oldText = obj.innerHTML;
        obj.innerHTML = 'Hide';
    }
}

function update_sharing(mode) {
    
    if (mode == 5)
    {
        document.getElementById('sharing_networks1_box').style.display = 'block';
        document.getElementById('sharing_networks2_box').style.display = 'none';
        //document.getElementById('sharing_custom_box').style.display = 'none';
    }
    else if (mode == 6)
    {
        document.getElementById('sharing_networks1_box').style.display = 'none';
        document.getElementById('sharing_networks2_box').style.display = 'block';
        //document.getElementById('sharing_custom_box').style.display = 'none';
    }
    else if (mode == 8)
    {
        document.getElementById('sharing_networks1_box').style.display = 'none';
        document.getElementById('sharing_networks2_box').style.display = 'none';
        //document.getElementById('sharing_custom_box').style.display = 'block';
    }
    else 
    {
        document.getElementById('sharing_networks1_box').style.display = 'none';
        document.getElementById('sharing_networks2_box').style.display = 'none';
        //document.getElementById('sharing_custom_box').style.display = 'none';
    }
}

function update_updating(mode) {

    if (mode == 3) 
    {
        document.getElementById('updating_networksmembers_box').style.display = 'block';
        document.getElementById('updating_networksadmins_box').style.display = 'none';
		document.getElementById('updating_somefriends_box').style.display = 'none';
        //document.getElementById('updating_custom_box').style.display = 'none';
    }
    else if (mode == 4)
    {
        document.getElementById('updating_networksmembers_box').style.display = 'none';
        document.getElementById('updating_networksadmins_box').style.display = 'block';
		document.getElementById('updating_somefriends_box').style.display = 'none';
        //document.getElementById('updating_custom_box').style.display = 'none';
    }
    else if (mode == 5)
    {
        document.getElementById('updating_networksmembers_box').style.display = 'none';
        document.getElementById('updating_networksadmins_box').style.display = 'none';
		document.getElementById('updating_somefriends_box').style.display = 'block';
        //document.getElementById('updating_custom_box').style.display = 'none';
    } 
    else if (mode == 7)
    {
        document.getElementById('updating_networksmembers_box').style.display = 'none';
        document.getElementById('updating_networksadmins_box').style.display = 'none';
		document.getElementById('updating_somefriends_box').style.display = 'none';
        //document.getElementById('updating_custom_box').style.display = 'block';
    }
    else
    {
        document.getElementById('updating_networksmembers_box').style.display = 'none';
        document.getElementById('updating_networksadmins_box').style.display = 'none';
		document.getElementById('updating_somefriends_box').style.display = 'none';
        //document.getElementById('updating_custom_box').style.display = 'none';
    }
}

function add_updaterpermission_string(permission_string) {
    var f = document.getElementById('updating_permissions_list');
    
    if (!f.hasValues)
    {
        f.innerHTML = permission_string;
        f.hasValues = 'true';
    }    
    else
    {
        f.innerHTML = f.innerHTML + '<br/>' + permission_string;
    }
}

