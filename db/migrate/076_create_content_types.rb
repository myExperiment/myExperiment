# myExperiment: db/migrate/076_create_content_types.rb
#
# Copyright (c) 2009 University of Manchester and the University of Southampton.
# See license.txt for details.

class CreateContentTypes < ActiveRecord::Migration
  def self.up
    create_table :content_types do |t|
      t.column :user_id, :integer
      t.column :title, :string
      t.column :description, :text
      t.column :description_html, :text
      t.column :mime_type, :string
      t.column :created_at, :datetime
      t.column :updated_at, :datetime
    end

    add_column :workflows,         :content_type_id, :integer
    add_column :workflow_versions, :content_type_id, :integer
    add_column :blobs,             :content_type_id, :integer

    # Create ContentType records for myExperiment

    u = User.find_by_username(Conf.admins.first)

    if u != nil

      # Create ContentType entries for the existing workflows

      workflow_type_to_content_type_id = {}

      Workflow.find(:all).map do |w|
        w.attributes["content_type"] end.uniq.each do |entry|

        mime_type = 'application/octet-stream'
        title     = nil

        if entry == 'application/vnd.taverna.scufl+xml'

          mime_type = 'application/vnd.taverna.scufl+xml'
          title     = 'Taverna 1'

        elsif entry == 'taverna2beta'

          title = 'Taverna 2 beta'

        elsif entry == 'trident_opc'

          title = 'Trident (Package)'

        elsif entry == 'application/xaml+xml'

          title     = 'Trident (XOML)'
          mime_type = 'application/xaml+xml'

        elsif entry == 'Excel 2007 Macro-Enabled Workbook'

          title     = 'Excel 2007 Macro-Enabled Workbook'
          mime_type = 'application/vnd.ms-excel.sheet.macroEnabled.12.xlsm'

        elsif entry == 'Makefile'

          title     = 'Makefile'
          mime_type = 'text/x-makefile'

        else

          title = entry

        end

        ft = ContentType.create(:user_id => u.id,
          :mime_type => mime_type,
          :title     => title)

        workflow_type_to_content_type_id[entry] = ft.id

      end

      # Create ContentType entries for the existing blobs

      blob_type_to_content_type_id = {}

      Blob.find(:all).map do |b|
        b.attributes["content_type"].strip end.uniq.each do |entry|
        if !blob_type_to_content_type_id[entry]
          ft = ContentType.create(:user_id => u.id, :mime_type => entry, :title => entry)

          blob_type_to_content_type_id[entry] = ft.id
        end
      end

      # Set the content_type_id for the existing workflows and blobs

      Workflow.find(:all).each do |w|
        execute("UPDATE workflows SET content_type_id = #{workflow_type_to_content_type_id[w.attributes["content_type"]]} WHERE id = #{w.id}")

        w.versions.each do |v|
          execute("UPDATE workflow_versions SET content_type_id = #{workflow_type_to_content_type_id[v.attributes["content_type"]]} WHERE id = #{v.id}")
        end
      end

      Blob.find(:all).each do |b|
        execute("UPDATE blobs SET content_type_id = #{blob_type_to_content_type_id[b.attributes["content_type"].strip]} WHERE id = #{b.id}")
      end
    end

    remove_column :workflows,         :content_type
    remove_column :workflow_versions, :content_type
    remove_column :blobs,             :content_type
  end

  def self.down
   
    add_column :workflows,         :content_type, :string
    add_column :workflow_versions, :content_type, :string
    add_column :blobs,             :content_type, :string

    remove_column :workflows,         :content_type_id
    remove_column :workflow_versions, :content_type_id
    remove_column :blobs,             :content_type_id

    drop_table :content_types
  end
end

