# myExperiment: lib/maintenance/backup.rb
#
# Copyright (c) 2010 University of Manchester and the University of Southampton.
# See license.txt for details.

require 'rubygems'
require 'mysql'

module Maintenance::Backup

  VERSION        = 1
  WORKING_DIR    = "tmp/backup"
  TMP_SQL_FILE   = "backup.sql"
  TMP_TABLE_NAME = "temp_table_for_filter"
  TMP_TABLE_FILE = "temp_table.sql"

  DEFAULT_BACKUP_FILENAME = "backup.tgz"

  def self.create(opts = {})

    @backup_filename = DEFAULT_BACKUP_FILENAME

    def self.backup_database

      def self.table(opts = {})

        args = []

        if opts[:model]
          models = opts[:model].find(:all)
          source_table_name = opts[:model].table_name
        else
          source_table_name = opts[:name]
        end

        if opts[:filter]

          if opts[:ids]

            ids = opts[:ids]

          else

            models = models.select do |model|

              if opts[:condition]
                model.send(opts[:condition])
              else
                if opts[:auth_object]
                  auth_object = model.send(opts[:auth_object])
                else
                  auth_object = model
                end

                if auth_object.class == User || auth_object.class == Network
                  true
                elsif auth_object.class == Contribution
                  [0, 1, 2].include?(auth_object.policy.share_mode)
                elsif auth_object.class == Policy
                  [0, 1, 2].include?(auth_object.share_mode)
                else
                  auth_object && [0, 1, 2].include?(auth_object.contribution.policy.share_mode)
                end
              end
            end

            ids = models.map do |model| model.id.to_s end

          end
        end

        if opts[:columns]
          out_file   = "#{WORKING_DIR}/#{TMP_TABLE_FILE}"
          table_name = TMP_TABLE_NAME

          source_table_name = source_table_name
          column_list       = opts[:columns].join(", ")

          mysql_execute("#{@mysql_database} -e 'CREATE TABLE #{TMP_TABLE_NAME} LIKE #{source_table_name}'")
          mysql_execute("#{@mysql_database} -e 'INSERT INTO #{TMP_TABLE_NAME} (#{column_list}) SELECT #{column_list} FROM #{source_table_name}'")

          system("rm -f #{WORKING_DIR}/#{TMP_TABLE_FILE}")

        else
          out_file   = "#{WORKING_DIR}/#{TMP_SQL_FILE}"
          table_name = source_table_name
        end

        args << "-u #{@mysql_user}"
        args << "--password=#{@mysql_password}"
        args << "--no-data" if opts[:no_data]
        args << "-h #{@mysql_host}"
        args << "#{@mysql_database}"
        args << "#{table_name} "
        args << "--where=\"id in (#{ids.join(",")})\"" if opts[:filter]

        # puts "cmd arguments = #{args.inspect}"

        system("mysqldump >> #{out_file} #{args.join(' ')}")

        if opts[:columns]
          mysql_execute("#{@mysql_database} -e 'DROP TABLE #{TMP_TABLE_NAME}'")

          system("sed -i -e 's/#{TMP_TABLE_NAME}/#{source_table_name}/' #{WORKING_DIR}/#{TMP_TABLE_FILE}")
          system("cat >> #{WORKING_DIR}/#{TMP_SQL_FILE} #{WORKING_DIR}/#{TMP_TABLE_FILE}")
        end
      end

      content_blob_ids = 

        (Workflow.find(:all) + Workflow::Version.find(:all) + Blob.find(:all)).select do |x|
          Authorization.is_authorized?('view', nil, x, nil)
        end.map do |x|
          x.content_blob_id
        end

      table(:model => ActivityLimit,          :no_data => true)
      table(:model => Announcement)
      table(:model => Attribution,            :filter  => true, :auth_object => "attributable")
      table(:name  => "auto_tables")
      table(:model => Blob,                   :filter  => true)
      table(:model => Blog,                   :no_data => true)
      table(:model => BlogPost,               :no_data => true)
      table(:model => Bookmark)
      table(:model => Citation,               :filter  => true, :auth_object => "workflow")
      table(:model => ClientApplication,      :no_data => true)
      table(:model => Comment,                :filter  => true, :auth_object => "commentable")
      table(:model => ContentBlob,            :filter  => true, :ids => content_blob_ids)
      table(:model => ContentType)
      table(:model => Contribution,           :filter  => true)
      table(:model => Creditation,            :filter  => true, :auth_object => "creditable")
      table(:model => CurationEvent,          :no_data => true)
      table(:model => Download,               :no_data => true)
      table(:model => Experiment,             :no_data => true)
      table(:model => Friendship)
      table(:model => GroupAnnouncement,      :filter  => true, :condition   => "public")
      table(:model => Job,                    :no_data => true)
      table(:model => KeyPermission,          :no_data => true)
      table(:model => License)
      table(:model => LicenseAttribute)
      table(:model => LicenseOption)
      table(:model => Membership)
      table(:model => Message,                :no_data => true)
      table(:model => Network)
      table(:model => OauthNonce,             :no_data => true)
      table(:model => OauthToken,             :no_data => true)
      table(:model => Pack,                   :filter  => true)
      table(:model => PackContributableEntry, :filter  => true, :auth_object => "pack")
      table(:model => PackRemoteEntry,        :filter  => true, :auth_object => "pack")
      table(:model => PendingInvitation,      :no_data => true)
      table(:model => Permission,             :no_data => true)
      table(:model => Picture,                :filter  => true, :condition   => "selected?")
      table(:model => PictureSelection)
      table(:name  => "plugin_schema_info")
      table(:model => Policy,                 :filter  => true)
      table(:model => Profile)
      table(:model => Rating,                 :filter  => true, :auth_object => "rateable")
      table(:name  => "relationships",        :no_data => true)
      table(:model => RemoteWorkflow,         :no_data => true)
      table(:model => Review,                 :filter  => true, :auth_object => "reviewable")
      table(:name  => "schema_info")
      table(:name  => "sessions",             :no_data => true)
      table(:model => Tag,                    :filter  => true, :condition   => "public?")
      table(:model => Tagging,                :filter  => true, :auth_object => "taggable")
      table(:model => TavernaEnactor,         :no_data => true)
      table(:model => User,                   :columns => [:id, :name, :created_at, :activated_at])
      table(:model => Viewing,                :no_data => true)
      table(:model => Vocabulary)
      table(:model => Workflow,               :filter  => true)
      table(:model => Workflow::Version,      :filter  => true, :auth_object => "workflow")
    end

    def self.backup_files

      def self.add_path(path, cmd)
        cmd << " #{path}" if File.exist?(path)
      end

      cmd = "tar czf #{@backup_filename}"

      Workflow.find(:all).select do |w|
        if Authorization.is_authorized?('view', nil, w, nil)
          add_path("public/workflow/image/#{w.id}", cmd)
          add_path("public/workflow/svg/#{w.id}",   cmd)
        end
      end

      Workflow::Version.find(:all).select do |wv|
        if Authorization.is_authorized?('view', nil, wv.workflow, nil)
          add_path("public/workflow/version/image/#{wv.id}", cmd)
          add_path("public/workflow/version/svg/#{wv.id}",   cmd)
        end
      end

      system("echo > #{WORKING_DIR}/version #{VERSION}")

      add_path("#{WORKING_DIR}/#{TMP_SQL_FILE}", cmd)
      add_path("#{WORKING_DIR}/version", cmd)

      # puts "cmd = #{cmd.inspect}"

      system(cmd)
    end

    db_config = YAML::load_file("config/database.yml")[ENV['RAILS_ENV'] || "development"]

    @mysql_host     = db_config["host"]
    @mysql_database = db_config["database"]
    @mysql_user     = db_config["username"]
    @mysql_password = db_config["password"]

    FileUtils.rm_rf(WORKING_DIR)
    FileUtils.mkdir_p(WORKING_DIR)

    backup_database
    backup_files

    FileUtils.rm_rf(WORKING_DIR)
  end

  def self.restore(opts = {})

    db_config = YAML::load_file("config/database.yml")[ENV['RAILS_ENV'] || "development"]

    @mysql_host     = db_config["host"]
    @mysql_database = db_config["database"]
    @mysql_user     = db_config["username"]
    @mysql_password = db_config["password"]

    @backup_filename = DEFAULT_BACKUP_FILENAME

    # Clear the file cache

    Rake::Task['tmp:cache:clear'].execute

    # Remove the pictures and workflow directories

    FileUtils.rm_rf("public/pictures")
    FileUtils.rm_rf("public/workflow")

    # Recreate the database

    mysql_execute("-e 'DROP DATABASE IF EXISTS #{@mysql_database}'")
    mysql_execute("-e 'CREATE DATABASE #{@mysql_database}'")

    # Extract the backup file

    FileUtils.rm_rf(WORKING_DIR)
    FileUtils.mkdir_p(WORKING_DIR)

    system("tar xzf #{@backup_filename}")

    # Check the version number

    backup_version = File.read("#{WORKING_DIR}/version").to_i

    if backup_version > VERSION
      raise "Cannot restore backup as backup file version (#{backup_version}) is " +
        "too high for the backup script to handle (#{VERSION})"
    end

    # Load database from the SQL dump

    mysql_execute("< #{WORKING_DIR}/#{TMP_SQL_FILE} #{@mysql_database}")

    FileUtils.rm_rf(WORKING_DIR)
  end

private

  def self.mysql_execute(statement)
    system("mysql -u #{@mysql_user} --password=#{@mysql_password} -h #{@mysql_host} #{statement}")
  end

end

