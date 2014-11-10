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
        ' <a href="" onclick="javascript:deleteTag(\'' + tags[i].replace("'", "\\'") +
        '\'); return false;"><img src="/images/famfamfam_silk/cross.png" class="icon" alt="Remove tag"/></a><br />';
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
var credit_users = new Object();
var credit_groups = new Object();

function updateAuthorList() {
	
	var markup = '';
	
	if (credit_me)
	{
		markup += 'Me <a href="" onclick="javascript:deleteAuthor(\'me\', null); ' +
            'return false;"><img src="/images/famfamfam_silk/cross.png" class="icon" alt="Remove"/></a><br />';
	}
	
	for (var key in credit_users)
	{
		markup += 'User: ' + credit_users[key] + ' <a href="" onclick="javascript:deleteAuthor(\'user\', ' + key + '); ' +
            'return false;"><img src="/images/famfamfam_silk/cross.png" class="icon" alt="Remove"/></a><br />';
	}
	
	for (var key in credit_groups)
	{
		markup += 'Group: ' + credit_groups[key] + ' <a href="" onclick="javascript:deleteAuthor(\'group\', ' + key + '); ' +
            'return false;"><img src="/images/famfamfam_silk/cross.png" class="icon" alt="Remove"/></a><br />';
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
	else 
	{
		document.getElementById('credits_me').value = "false";
	}
	
	// Users (friends + other users)
	var users_list = '';
	
	for (var key in credit_users)
	{
		users_list += key + ',';
	}
	
	document.getElementById('credits_users').value = users_list;
	
	// Groups
	var groups_list = '';
	
	for (var key in credit_groups)
	{
		groups_list += key + ',';
	} 
	
	document.getElementById('credits_groups').value = groups_list;
}

function addAuthor(author_option, author_id, author_name) {
    
	// Me
  if (author_option == 1)
	{
		credit_me = true;
	}
	// One of my Friends 
	else if (author_option == 2)
	{
		var x = document.getElementById('author_friends_dropdown');
		
		if (x.options.length > 0 && x.selectedIndex != 0)
		{
			var y = x.options[x.selectedIndex];
	    credit_users[y.value] = y.text;
		}
	}
	// A user on myExperiment who is not a Friend.
	else if (author_option == 3)
	{
    credit_users[other_user_id] = other_user_name;
    other_user_id = null;
    other_user_name = null;
    $('user_name').value = '';
    $('add_otheruser_author').disabled = true;
	}
	// A myExperiment Group
	else if (author_option == 4)
	{
    credit_groups[group_id] = group_name;
    group_id = null;
    group_name = null;
    $('group_name').value = '';
    $('add_group_author').disabled = true;
	}
	
	updateAuthorList();
}

function deleteAuthor(type, key) {

	if (type == 'me')
	{
		credit_me = false;
	}
	else if (type == 'user')
	{
		delete credit_users[key];
	}
	else if (type == 'group')
	{
		delete credit_groups[key];
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

var attributions_workflows = new Object();
var attributions_files = new Object();

function updateAttributionsList() {
	
	var markup = '';
	
	for (var key in attributions_workflows)
	{
		markup += 'Workflow: ' + attributions_workflows[key] + '&nbsp;&nbsp;&nbsp;<small>[<a href="" onclick="javascript:deleteAttribution(\'workflow\', ' + key + '); ' +
    		'return false;">delete</a>]</small><br/>';
	}
	
	for (var key in attributions_files)
	{
		markup += 'File: ' + attributions_files[key] + '&nbsp;&nbsp;&nbsp;<small>[<a href="" onclick="javascript:deleteAttribution(\'file\', ' + key + '); ' +
    		'return false;">delete</a>]</small><br/>';
	}
	
	if (markup == '')
	{
		markup = '<i>None</i>';
	}
	
	document.getElementById('attribution_list').innerHTML = markup;
	
	// Also update web form (the hidden input fields)
	
	var attr_workflows_list = '';
	
	for (var key in attributions_workflows)
	{
		attr_workflows_list += key + ',';
	}
	
	document.getElementById('attributions_workflows').value = attr_workflows_list;
	
	var attr_files_list = '';
	
	for (var key in attributions_files)
	{
		attr_files_list += key + ',';
	} 
	
	document.getElementById('attributions_files').value = attr_files_list;
}

function addAttribution(type) {
	
	if (type == 'existing_workflow') {
    attributions_workflows[workflow_id] = workflow_name;
    workflow_id = null;
    workflow_name = null;
    $('workflow_name').value = '';
    $('add_workflow_attrib').disabled = true;
	}
	else if (type == 'existing_file') {
    attributions_files[file_id] = file_name;
    file_id = null;
    file_name = null;
    $('file_name').value = '';
    $('add_file_attrib').disabled = true;
	} 
	
	updateAttributionsList();
}

function deleteAttribution(type, id) {
	
	if (type == 'workflow') {
		delete attributions_workflows[id];
	}
	else if (type == 'file') {
		delete attributions_files[id];
	}
	
	updateAttributionsList();
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
    
    /*
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
    */
}

function update_updating(mode) {

    if (mode == 5)
    {
				document.getElementById('updating_somefriends_box').style.display = 'block';
        //document.getElementById('updating_custom_box').style.display = 'none';
    }
    else
    {
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

