#!/usr/bin/php 
<?php
	//Database Connection
	$user="root";
        $password="";
        $server="localhost";
        $database="m2_production";
        mysql_connect($server,$user,$password);
        mysql_select_db($database);
	
	//Salt of Anonomysing Users
	$salt="changeme";
	
	//The tables and positions of fields to be hashed to anonymise them
	$createhashes['downloads']=2;
	$createhashes['viewings']=2;

	//Create Table Statements
	$createtable['announcements']="CREATE TABLE announcements (
  id int(11) NOT NULL auto_increment,
  title varchar(255) default NULL,
  user_id int(11) default NULL,
  created_at datetime default NULL,
  updated_at datetime default NULL,
  body text,
  body_html text,
  PRIMARY KEY  (id)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;";
	$createtable['attributions']="CREATE TABLE attributions (
  id int(11) NOT NULL auto_increment,
  attributor_id int(11) default NULL,
  attributor_type varchar(255) default NULL,
  attributable_id int(11) default NULL,
  attributable_type varchar(255) default NULL,
  created_at datetime default NULL,
  updated_at datetime default NULL,
  PRIMARY KEY  (id)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;";
	$createtable['blobs']="CREATE TABLE blobs (
  id int(11) NOT NULL auto_increment,
  contributor_id int(11) default NULL,
  contributor_type varchar(255) default NULL,
  local_name varchar(255) default NULL,
  content_type varchar(255) default NULL,
  created_at datetime default NULL,
  updated_at datetime default NULL,
  title varchar(255) default NULL,
  body text,
  license varchar(10) NOT NULL default 'by-nd',
  body_html text,
  content_blob_id int(11) default NULL,
  PRIMARY KEY  (id)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;";
	$createtable['bookmarks']="CREATE TABLE bookmarks (
  id int(11) NOT NULL auto_increment,
  title varchar(50) default '',
  created_at datetime NOT NULL default '0000-00-00 00:00:00',
  bookmarkable_type varchar(15) NOT NULL default '',
  bookmarkable_id int(11) NOT NULL default '0',
  user_id int(11) NOT NULL default '0',
  PRIMARY KEY  (id),
  KEY fk_bookmarks_user (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;";
	$createtable['citations']="CREATE TABLE citations (
  id int(11) NOT NULL auto_increment,
  user_id int(11) default NULL,
  workflow_id int(11) default NULL,
  workflow_version int(11) default NULL,
  authors text,
  title varchar(255) default NULL,
  publication varchar(255) default NULL,
  published_at datetime default NULL,
  accessed_at datetime default NULL,
  url varchar(255) default NULL,
  isbn varchar(255) default NULL,
  issn varchar(255) default NULL,
  created_at datetime default NULL,
  updated_at datetime default NULL,
  PRIMARY KEY  (id)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;";
	$createtable['comments']="CREATE TABLE comments (
  id int(11) NOT NULL auto_increment,
  title varchar(50) default '',
  `comment` text,
  created_at datetime NOT NULL default '0000-00-00 00:00:00',
  commentable_id int(11) NOT NULL default '0',
  commentable_type varchar(15) NOT NULL default '',
  user_id int(11) NOT NULL default '0',
  PRIMARY KEY  (id),
  KEY fk_comments_user (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;";
	$createtable['contributions']="
CREATE TABLE contributions (
  id int(11) NOT NULL auto_increment,
  contributor_id int(11) default NULL,
  contributor_type varchar(255) default NULL,
  contributable_id int(11) default NULL,
  contributable_type varchar(255) default NULL,
  policy_id int(11) default NULL,
  created_at datetime default NULL,
  updated_at datetime default NULL,
  downloads_count int(11) default '0',
  viewings_count int(11) default '0',
  PRIMARY KEY  (id)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;";
	$createtable['creditations']="CREATE TABLE creditations (
  id int(11) NOT NULL auto_increment,
  creditor_id int(11) default NULL,
  creditor_type varchar(255) default NULL,
  creditable_id int(11) default NULL,
  creditable_type varchar(255) default NULL,
  created_at datetime default NULL,
  updated_at datetime default NULL,
  PRIMARY KEY  (id)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;";
	$createtable['downloads']="CREATE TABLE downloads (
  id int(11) NOT NULL auto_increment,
  contribution_id int(11) default NULL,
  user_id char(32) default NULL,
  created_at datetime default NULL,
  PRIMARY KEY  (id)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;";
	$createtable['experiments']="CREATE TABLE experiments (
  id int(11) NOT NULL auto_increment,
  title varchar(255) default NULL,
  description text,
  description_html text,
  contributor_id int(11) default NULL,
  contributor_type varchar(255) default NULL,
  created_at datetime default NULL,
  updated_at datetime default NULL,
  PRIMARY KEY  (id)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;";
	$createtable['friendships']="CREATE TABLE friendships (
  id int(11) NOT NULL auto_increment,
  user_id int(11) default NULL,
  friend_id int(11) default NULL,
  created_at datetime default NULL,
  accepted_at datetime default NULL,
  message varchar(500) default NULL,
  PRIMARY KEY  (id)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;";
	$createtable['group_announcements']="CREATE TABLE group_announcements (
  id int(11) NOT NULL auto_increment,
  title varchar(255) default NULL,
  network_id int(11) default NULL,
  user_id int(11) default NULL,
  public tinyint(1) default '0',
  created_at datetime default NULL,
  updated_at datetime default NULL,
  body text,
  body_html text,
  PRIMARY KEY  (id)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;";
	$createtable['jobs']="CREATE TABLE jobs (
  id int(11) NOT NULL auto_increment,
  title varchar(255) default NULL,
  description text,
  description_html text,
  experiment_id int(11) default NULL,
  user_id int(11) default NULL,
  runnable_id int(11) default NULL,
  runnable_version int(11) default NULL,
  runnable_type varchar(255) default NULL,
  runner_id int(11) default NULL,
  runner_type varchar(255) default NULL,
  submitted_at datetime default NULL,
  started_at datetime default NULL,
  completed_at datetime default NULL,
  last_status varchar(255) default NULL,
  last_status_at datetime default NULL,
  job_uri varchar(255) default NULL,
  job_manifest longblob,
  inputs_uri varchar(255) default NULL,
  inputs_data longblob,
  outputs_uri varchar(255) default NULL,
  created_at datetime default NULL,
  updated_at datetime default NULL,
  parent_job_id int(11) default NULL,
  PRIMARY KEY  (id)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;";
	$createtable['memberships']="CREATE TABLE memberships (
  id int(11) NOT NULL auto_increment,
  user_id int(11) default NULL,
  network_id int(11) default NULL,
  created_at datetime default NULL,
  user_established_at datetime default NULL,
  network_established_at datetime default NULL,
  message varchar(500) default NULL,
  PRIMARY KEY  (id)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;";
	$createtable['messages']="CREATE TABLE messages (
  id int(11) NOT NULL auto_increment,
  `from` int(11) default NULL,
  `to` int(11) default NULL,
  `subject` varchar(255) default NULL,
  body text,
  reply_id int(11) default NULL,
  created_at datetime default NULL,
  read_at datetime default NULL,
  body_html text,
  deleted_by_sender tinyint(1) default '0',
  deleted_by_recipient tinyint(1) default '0',
  PRIMARY KEY  (id)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;";
	$createtable['networks']="CREATE TABLE networks (
  id int(11) NOT NULL auto_increment,
  user_id int(11) default NULL,
  title varchar(255) default NULL,
  unique_name varchar(255) default NULL,
  created_at datetime default NULL,
  updated_at datetime default NULL,
  description text,
  description_html text,
  auto_accept tinyint(1) default '0',
  PRIMARY KEY  (id)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;";

	$createtable['pack_contributable_entries']="
CREATE TABLE pack_contributable_entries (
  id int(11) NOT NULL auto_increment,
  pack_id int(11) NOT NULL,
  contributable_id int(11) NOT NULL,
  contributable_version int(11) default NULL,
  contributable_type varchar(255) NOT NULL,
  `comment` text,
  user_id int(11) NOT NULL,
  created_at datetime default NULL,
  updated_at datetime default NULL,
  PRIMARY KEY  (id)
) ENGINE=MyISAM  DEFAULT CHARSET=latin1;";
	$createtable['pack_remote_entries']="
CREATE TABLE pack_remote_entries (
  id int(11) NOT NULL auto_increment,
  pack_id int(11) NOT NULL,
  title varchar(255) NOT NULL,
  uri varchar(255) NOT NULL,
  alternate_uri varchar(255) default NULL,
  `comment` text,
  user_id int(11) NOT NULL,
  created_at datetime default NULL,
  updated_at datetime default NULL,
  PRIMARY KEY  (id)
) ENGINE=MyISAM  DEFAULT CHARSET=latin1;";
	$createtable['packs']="CREATE TABLE packs (
  id int(11) NOT NULL auto_increment,
  contributor_id int(11) default NULL,
  contributor_type varchar(255) default NULL,
  title varchar(255) default NULL,
  description text,
  description_html text,
  created_at datetime default NULL,
  updated_at datetime default NULL,
  PRIMARY KEY  (id)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;";
	$createtable['pending_invitations']="
CREATE TABLE pending_invitations (
  id int(11) NOT NULL auto_increment,
  email varchar(255) default NULL,
  created_at datetime default NULL,
  request_type varchar(255) default NULL,
  requested_by int(11) default NULL,
  request_for int(11) default NULL,
  message varchar(500) default NULL,
  token varchar(255) default NULL,
  PRIMARY KEY  (id)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;";
	$createtable['permissions']="
CREATE TABLE permissions (
  id int(11) NOT NULL auto_increment,
  contributor_id int(11) default NULL,
  contributor_type varchar(255) default NULL,
  policy_id int(11) default NULL,
  download tinyint(1) default '0',
  edit tinyint(1) default '0',
  `view` tinyint(1) default '0',
  created_at datetime default NULL,
  updated_at datetime default NULL,
  PRIMARY KEY  (id)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;";
	$createtable['picture_selections']="CREATE TABLE picture_selections (
  id int(11) NOT NULL auto_increment,
  user_id int(11) default NULL,
  picture_id int(11) default NULL,
  created_at datetime default NULL,
  PRIMARY KEY  (id)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;";
	$createtable['pictures']="CREATE TABLE pictures (
  id int(11) NOT NULL auto_increment,
  `data` mediumblob,
  user_id int(11) default NULL,
  PRIMARY KEY  (id)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;";
	$createtable['policies']="CREATE TABLE policies (
  id int(11) NOT NULL auto_increment,
  contributor_id int(11) default NULL,
  contributor_type varchar(255) default NULL,
  `name` varchar(255) default NULL,
  download_public tinyint(1) default '1',
  edit_public tinyint(1) default '1',
  view_public tinyint(1) default '1',
  download_protected tinyint(1) default '1',
  edit_protected tinyint(1) default '1',
  view_protected tinyint(1) default '1',
  created_at datetime default NULL,
  updated_at datetime default NULL,
  share_mode int(11) default NULL,
  update_mode int(11) default NULL,
  PRIMARY KEY  (id)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;";
	$createtable['profiles']="CREATE TABLE profiles (
  id int(11) NOT NULL auto_increment,
  user_id int(11) default NULL,
  picture_id int(11) default NULL,
  email varchar(255) default NULL,
  website varchar(255) default NULL,
  created_at datetime default NULL,
  updated_at datetime default NULL,
  body text,
  body_html text,
  field_or_industry varchar(255) default NULL,
  occupation_or_roles varchar(255) default NULL,
  organisations text,
  location_city varchar(255) default NULL,
  location_country varchar(255) default NULL,
  interests text,
  contact_details text,
  PRIMARY KEY  (id)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;";
	$createtable['ratings']="CREATE TABLE ratings (
  id int(11) NOT NULL auto_increment,
  rating int(11) default '0',
  created_at datetime NOT NULL default '0000-00-00 00:00:00',
  rateable_type varchar(15) NOT NULL default '',
  rateable_id int(11) NOT NULL default '0',
  user_id int(11) NOT NULL default '0',
  PRIMARY KEY  (id),
  KEY fk_ratings_user (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;";
	$createtable['remote_workflows']="CREATE TABLE remote_workflows (
  id int(11) NOT NULL auto_increment,
  workflow_id int(11) default NULL,
  workflow_version int(11) default NULL,
  taverna_enactor_id int(11) default NULL,
  workflow_uri varchar(255) default NULL,
  PRIMARY KEY  (id)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;";
	$createtable['reviews']="CREATE TABLE reviews (
  id int(11) NOT NULL auto_increment,
  title varchar(255) default '',
  review text,
  created_at datetime NOT NULL default '0000-00-00 00:00:00',
  updated_at datetime NOT NULL default '0000-00-00 00:00:00',
  reviewable_id int(11) NOT NULL default '0',
  reviewable_type varchar(15) NOT NULL default '',
  user_id int(11) NOT NULL default '0',
  PRIMARY KEY  (id),
  KEY fk_reviews_user (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;";
	$createtable['taggings']="CREATE TABLE taggings (
  id int(11) NOT NULL auto_increment,
  tag_id int(11) default NULL,
  taggable_id int(11) default NULL,
  taggable_type varchar(255) default NULL,
  user_id int(11) default NULL,
  created_at datetime default NULL,
  PRIMARY KEY  (id),
  KEY index_taggings_on_tag_id_and_taggable_type (tag_id,taggable_type),
  KEY index_taggings_on_user_id_and_tag_id_and_taggable_type (user_id,tag_id,taggable_type),
  KEY index_taggings_on_taggable_id_and_taggable_type (taggable_id,taggable_type),
  KEY index_taggings_on_user_id_and_taggable_id_and_taggable_type (user_id,taggable_id,taggable_type)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;";
	$createtable['tags']="CREATE TABLE tags (
  id int(11) NOT NULL auto_increment,
  `name` varchar(255) default NULL,
  taggings_count int(11) NOT NULL default '0',
  PRIMARY KEY  (id),
  KEY index_tags_on_name (`name`),
  KEY index_tags_on_taggings_count (taggings_count)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;";
	$createtable['taverna_enactors']="CREATE TABLE taverna_enactors (
  id int(11) NOT NULL auto_increment,
  title varchar(255) default NULL,
  description text,
  contributor_id int(11) default NULL,
  contributor_type varchar(255) default NULL,
  url varchar(255) default NULL,
  username varchar(255) default NULL,
  crypted_password varchar(255) default NULL,
  created_at datetime default NULL,
  updated_at datetime default NULL,
  PRIMARY KEY  (id)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;";

	$createtable['users']="CREATE TABLE users (
  id int(11) NOT NULL auto_increment,
  openid_url varchar(255) default NULL,
  `name` varchar(255) default NULL,
  created_at datetime default NULL,
  updated_at datetime default NULL,
  last_seen_at datetime default NULL,
  username varchar(255) default NULL,
  downloads_count int(11) default '0',
  viewings_count int(11) default '0',
  email varchar(255) default NULL,
  unconfirmed_email varchar(255) default NULL,
  email_confirmed_at datetime default NULL,
  activated_at datetime default NULL,
  receive_notifications tinyint(1) default '1',
  PRIMARY KEY  (id)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;";
	$createtable['viewings']="CREATE TABLE viewings (
  id int(11) NOT NULL auto_increment,
  contribution_id int(11) default NULL,
  user_id char(32) default NULL,
  created_at datetime default NULL,
  PRIMARY KEY  (id)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;";
	$createtable['workflow_versions']="CREATE TABLE workflow_versions (
  id int(11) NOT NULL auto_increment,
  workflow_id int(11) default NULL,
  version int(11) default NULL,
  contributor_id int(11) default NULL,
  contributor_type varchar(255) default NULL,
  title varchar(255) default NULL,
  unique_name varchar(255) default NULL,
  body text,
  body_html text,
  created_at datetime default NULL,
  updated_at datetime default NULL,
  image varchar(255) default NULL,
  svg varchar(255) default NULL,
  revision_comments text,
  content_type varchar(255) default NULL,
  content_blob_id int(11) default NULL,
  file_ext varchar(255) default NULL,
  last_edited_by varchar(255) default NULL,
  PRIMARY KEY  (id)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;";
	$createtable['workflows']="CREATE TABLE workflows (
  id int(11) NOT NULL auto_increment,
  contributor_id int(11) default NULL,
  contributor_type varchar(255) default NULL,
  image varchar(255) default NULL,
  svg varchar(255) default NULL,
  title varchar(255) default NULL,
  unique_name varchar(255) default NULL,
  body text,
  body_html text,
  created_at datetime default NULL,
  updated_at datetime default NULL,
  license varchar(10) NOT NULL default 'by-nd',
  current_version int(11) default NULL,
  content_type varchar(255) default NULL,
  content_blob_id int(11) default NULL,
  file_ext varchar(255) default NULL,
  last_edited_by varchar(255) default NULL,
  PRIMARY KEY  (id)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;";

	//SQL Statements for getting public entities
	$publicsql['announcements']="select * from announcements";
        $publicsql['attributions']="select attributions.* from attributions inner join contributions on attributions.attributor_id=contributions.contributable_id and attributions.attributor_type=contributions.contributable_type inner join policies on contributions.policy_id=policies.id where policies.view_public=1";
	$publicsql['blobs']="select blobs.* from blobs inner join contributions on contributions.contributable_id=blobs.id inner join policies on contributions.policy_id=policies.id where contributable_type='Blob' and policies.view_public=1";
	$publicsql['bookmarks']="select bookmarks.* from bookmarks inner join contributions on bookmarks.bookmarkable_id=contributions.contributable_id and bookmarks.bookmarkable_type=contributions.contributable_type inner join policies on contributions.policy_id=policies.id where policies.view_public=1";
	$publicsql['citations']="select citations.* from citations inner join contributions on citations.workflow_id=contributions.contributable_id and contributions.contributable_type='Workflow' inner join policies on contributions.policy_id=policies.id where policies.view_public=1";        
	$publicsql['comments']="select comments.* from comments left join contributions on comments.commentable_id=contributions.contributable_id and comments.commentable_type=contributions.contributable_type left join policies on contributions.policy_id=policies.id where (policies.view_public=1 or comments.commentable_type='Network') and comments.commentable_type in ('Workflow','Blob','Pack','Network')";
	$publicsql['contributions']="select contributions.* from contributions inner join policies on contributions.policy_id=policies.id where policies.view_public=1";
        $publicsql['creditations']="select creditations.* from creditations inner join contributions on creditations.creditable_id=contributions.contributable_id and creditations.creditable_type=contributions.contributable_type inner join policies on contributions.policy_id=policies.id where policies.view_public=1";
        $publicsql['downloads']="select downloads.* from downloads inner join contributions on downloads.contribution_id=contributions.id inner join policies on contributions.policy_id=policies.id where policies.view_public=1";
        $publicsql['experiments']="select * from experiments";
        $publicsql['friendships']="select * from friendships";
        
	$publicsql['group_announcements']="select * from group_announcements where public=1";
	
        $publicsql['jobs']="select jobs.* from jobs inner join contributions on jobs.runnable_id=contributions.contributable_id and jobs.runnable_type=contributions.contributable_type inner join policies on contributions.policy_id=policies.id where policies.view_public=1";
        
        $publicsql['memberships']="select * from memberships";
        $publicsql['messages']="select * from messages where 1=0";
	$publicsql['networks']="select * from networks";
        $publicsql['packs']="select packs.* from packs inner join contributions on packs.id=contributions.contributable_id and contributions.contributable_type='Pack' inner join policies on contributions.policy_id=policies.id where policies.view_public=1";
	$publicsql['pack_contributable_entries']="select pack_contributable_entries.* from pack_contributable_entries inner join packs on pack_contributable_entries.pack_id=packs.id inner join contributions on packs.id=contributions.contributable_id and contributions.contributable_type='Pack' inner join policies on contributions.policy_id=policies.id where policies.view_public=1";
	$publicsql['pack_remote_entries']="select pack_remote_entries.* from pack_remote_entries inner join packs on pack_remote_entries.pack_id=packs.id inner join contributions on packs.id=contributions.contributable_id and contributions.contributable_type='Pack' inner join policies on contributions.policy_id=policies.id where policies.view_public=1";
	$publicsql['pending_invitations']="select * from pending_invitations where 1=0";
	$publicsql['permissions']="select permissions.* from permissions inner join policies on permissions.policy_id=policies.id where policies.view_public=1";
	$publicsql['pictures']="select * from pictures";
	$publicsql['picture_selections']="select * from picture_selections";
	$publicsql['policies']="select * from policies where view_public=1";
	$publicsql['profiles']="select * from profiles";
        $publicsql['ratings']="select ratings.* from ratings inner join contributions on ratings.rateable_id=contributions.contributable_id and ratings.rateable_type=contributions.contributable_type inner join policies on contributions.policy_id=policies.id where policies.view_public=1";
	$publicsql['remote_workflows']="select remote_workflows.* from remote_workflows inner join contributions on remote_workflows.workflow_id=contributions.contributable_id and contributions.contributable_type='Workflow' inner join policies on contributions.policy_id=policies.id where policies.view_public=1 and 1=0";

        $publicsql['reviews']="select reviews.* from reviews inner join contributions on reviews.reviewable_id=contributions.contributable_id and reviews.reviewable_type=contributions.contributable_type inner join policies on contributions.policy_id=policies.id where policies.view_public=1";
        $publicsql['taverna_enactors']="select * from taverna_enactors where 1=0";
        $publicsql['taggings']="select taggings.* from taggings left join contributions on taggings.taggable_id=contributions.contributable_id and taggings.taggable_type=contributions.contributable_type left join policies on contributions.policy_id=policies.id where policies.view_public=1 or taggings.taggable_type='Network'";
        $publicsql['users']="select id, openid_url, name, created_at, updated_at, last_seen_at, username, downloads_count, viewings_count, email, unconfirmed_email, email_confirmed_at, activated_at, receive_notifications from users";
	$publicsql['viewings']="select viewings.* from viewings inner join contributions on viewings.contribution_id=contributions.id inner join policies on contributions.policy_id=policies.id where policies.view_public=1";        
	$publicsql['workflows']="select workflows.* from contributions inner join workflows on contributions.contributable_id=workflows.id inner join policies on contributions.policy_id=policies.id where contributable_type='Workflow' and policies.view_public=1";
        $publicsql['workflow_versions']="select workflow_versions.* from contributions inner join workflows on contributions.contributable_id=workflows.id inner join workflow_versions on workflows.id=workflow_versions.workflow_id inner join policies on contributions.policy_id=policies.id where contributable_type='Workflow' and policies.view_public=1";

	//SQL statements for determining IDs of public content blobs
	$cbsql[]="select content_blobs.id from content_blobs inner join blobs on content_blobs.id=blobs.content_blob_id inner join contributions on blobs.id=contributions.contributable_id and contributions.contributable_type='Blob' inner join policies on contributions.policy_id = policies.id where policies.view_public=1";
	        $cbsql[]="select content_blobs.id from content_blobs inner join workflows on content_blobs.id=workflows.content_blob_id inner join contributions on workflows.id=contributions.contributable_id and contributions.contributable_type='Workflow' inner join policies on contributions.policy_id = policies.id where policies.view_public=1";
		        $cbsql[]="select content_blobs.id from content_blobs inner join workflow_versions on content_blobs.id=workflow_versions.content_blob_id inner join contributions on workflow_versions.workflow_id=contributions.contributable_id and contributions.contributable_type='Workflow' inner join policies on contributions.policy_id = policies.id where policies.view_public=1";

	
	//SQL File Generation

	//Find all ids for public content_blobs
	foreach ($cbsql as $sql){
                $cbres=mysql_query($sql);
                $cbnum=mysql_num_rows($cbres);
                for ($i=0; $i<$cbnum; $i++){
                        $cbids[]=mysql_result($cbres,$i,'id');
                }
        }
        $cbids=array_unique($cbids);

	//Add content blob ids to where clause of mysqldump statement
        $whereclause = "id in (";
        foreach ($cbids as $cbid){
                $whereclause.="$cbid,";
        }
        $whereclause.="0)";

	//Save mysqldump of public content blobs to myexp_public.sql
	if ($password){
		exec("mysqldump -u root -p -w\"$whereclause\" --max-allowed-packet=256M --skip-comments $database content_blobs > myexp_public.sql");
	}
	else exec("mysqldump -u root -w\"$whereclause\" --max-allowed-packet=256M --skip-comments $database content_blobs > myexp_public.sql");

	//Open up SQL file to append all the other tables
	$fh=fopen('myexp_public.sql','a');
	foreach ($publicsql as $table => $sql){

		//Get the all the public entities for a particular table
		if (is_array($sql)){
			for ($s=0; $s<sizeof($sql); $s++){
				$res[$s]=mysql_query($sql[$s]);
				$num[$s]=mysql_num_rows($res[$s]);
			}
			
		}
		else{
			$res[0]=mysql_query($sql);
			$num[0]=mysql_num_rows($res[0]);
		}

		//Drop and recreate table if necessary
		fwrite($fh,"DROP TABLE IF EXISTS `$table`;\n");
		fwrite($fh,$createtable[$table]."\n");

		//Insert statements for current table
		foreach ($res as $resnum => $result){	
			for ($i=0; $i<$num[$resnum]; $i++){
				$row=mysql_fetch_row($result);
				$insline="INSERT INTO `$table` values(";
				for ($f=0; $f<sizeof($row)-1; $f++){
					if ($createhashes[$table]==$f && $f>0) $row[$f]=md5($salt.$row[$f]);
					$insline.="'".mysql_escape_string($row[$f])."',";
				}
				$insline.="'".mysql_escape_string($row[sizeof($row)-1])."');\n";
				fwrite($fh,$insline);
			}
		}
		fwrite($fh,"\n");
	}
	fclose($fh);
?>
	

			
