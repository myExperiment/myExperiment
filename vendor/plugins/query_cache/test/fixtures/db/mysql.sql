CREATE TABLE `tasks` (
  `id` int(11) NOT NULL auto_increment,
  `starting` datetime NULL default '0000-00-00 00:00:00',
  `ending` datetime NULL default '0000-00-00 00:00:00',
  PRIMARY KEY  (`id`)
) TYPE=InnoDB;

CREATE TABLE `topics` (
  `id` int(11) NOT NULL auto_increment,
  `title` varchar(255) default NULL,
  `author_name` varchar(255) default NULL,
  `author_email_address` varchar(255) default NULL,
  `written_on` datetime default NULL,
  `bonus_time` time default NULL,
  `last_read` date default NULL,
  `content` text,
  `approved` tinyint(1) default 1,
  `replies_count` int(11) default 0,
  `parent_id` int(11) default NULL,
  `type` varchar(50) default NULL,
  PRIMARY KEY  (`id`)
) TYPE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `courses` (
 `id` INTEGER NOT NULL PRIMARY KEY,
 `name` VARCHAR(255) NOT NULL
) TYPE=InnoDB;

