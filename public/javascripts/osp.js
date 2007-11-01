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
        ' <small>[<a href="" onclick="javascript:deleteTag(\'' + tags[i] +
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

function toggle_visibility(id) {
   var e = document.getElementById(id);
   if(e.style.display == 'block')
      e.style.display = 'none';
   else
      e.style.display = 'block';
}

function add_author() {
    var f = document.getElementById('authors_list');
    
    var form = document.getElementById('new_workflow_form');
    
    var author_string = '';
    
    // Note that the code belows requires that the <form> element in which the radio buttons are in 
    // have to have an id of 'new_workflow_form'
    
    if (form.add_author_option[0].checked == true)
    {
        var x = document.getElementById('author_friends_dropdown');
        author_string = 'Friend: ' + x.options[x.selectedIndex].text;
    }
    else if (form.add_author_option[1].checked == true)
    {
        var x = document.getElementById('author_otheruser_dropdown');
        author_string = 'Other myExperiment user: ' + x.options[x.selectedIndex].text;
    }
    else if (form.add_author_option[2].checked == true)
    {
        var x = document.getElementById('author_someoneelse_forenames');
        var y = document.getElementById('author_someoneelse_surname');
        
        author_string = 'Someone else: ' + x.value + ' ' + y.value;   
        
        x.value = '';
        y.value = '';     
    }
    else if (form.add_author_option[3].checked == true)
    {
        var x = document.getElementById('author__organisation');
        
        author_string = 'Organisation: ' + x.value;
        
        x.value = '';
    }
    else if (form.add_author_option[4].checked == true)
    {
        var x = document.getElementById('author_networks_dropdown');
        author_string = 'A myExperiment Network: ' + x.options[x.selectedIndex].text;
    }
    
    f.innerHTML = f.innerHTML + '<br/>' + author_string;
}

function update_author(parentId) {
    
    if (parentId == 'author_option_2')
    {
        document.getElementById('author_friends_box').style.display = 'block';
        document.getElementById('author_otheruser_box').style.display = 'none';
        document.getElementById('author_someoneelse_box').style.display = 'none';
        document.getElementById('author_organisation_box').style.display = 'none';
        document.getElementById('author_networks_box').style.display = 'none';
    }
    else if (parentId == 'author_option_3')
    {
        document.getElementById('author_friends_box').style.display = 'none';
        document.getElementById('author_otheruser_box').style.display = 'none';
        document.getElementById('author_someoneelse_box').style.display = 'block';
        document.getElementById('author_organisation_box').style.display = 'none';
        document.getElementById('author_networks_box').style.display = 'none';
    }
    else if (parentId == 'author_option_4')
    {
        document.getElementById('author_friends_box').style.display = 'none';
        document.getElementById('author_otheruser_box').style.display = 'none';
        document.getElementById('author_someoneelse_box').style.display = 'none';
        document.getElementById('author_organisation_box').style.display = 'block';
        document.getElementById('author_networks_box').style.display = 'none';
    }
    else if (parentId == 'author_option_6')
    {
        document.getElementById('author_friends_box').style.display = 'none';
        document.getElementById('author_otheruser_box').style.display = 'block';
        document.getElementById('author_someoneelse_box').style.display = 'none';
        document.getElementById('author_organisation_box').style.display = 'none';
        document.getElementById('author_networks_box').style.display = 'none';
    }
    else if (parentId == 'author_option_5')
    {
        document.getElementById('author_friends_box').style.display = 'none';
        document.getElementById('author_otheruser_box').style.display = 'none';
        document.getElementById('author_someoneelse_box').style.display = 'none';
        document.getElementById('author_organisation_box').style.display = 'none';
        document.getElementById('author_networks_box').style.display = 'block';
    }
    else
    {
        document.getElementById('author_friends_box').style.display = 'none';
        document.getElementById('author_otheruser_box').style.display = 'none';
        document.getElementById('author_someoneelse_box').style.display = 'none';
        document.getElementById('author_organisation_box').style.display = 'none';
        document.getElementById('author_networks_box').style.display = 'none';
    }
}

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

function add_workflowreference_string(workflow_string) {
    var f = document.getElementById('basedon_workflows_list');
    
    if (!f.hasValues)
    {
        f.innerHTML = workflow_string;
        f.hasValues = 'true';
    }    
    else
    {
        f.innerHTML = f.innerHTML + '<br/>' + workflow_string;
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

