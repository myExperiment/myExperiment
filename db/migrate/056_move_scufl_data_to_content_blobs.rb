class MoveScuflDataToContentBlobs < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.record_timestamps = false

    Workflow.find(:all).each do |w|

      w.versions.each do |wv|
        wv.content_blob = ContentBlob.new(:data => wv.scufl)
        wv.save
      end

      current = w.find_version(w.current_version)
      w.content_blob = current.content_blob

      w.save
    end

    remove_column :workflows, :scufl
    remove_column :workflow_versions, :scufl

    ActiveRecord::Base.record_timestamps = true
  end

  def self.down
    ActiveRecord::Base.record_timestamps = false

    add_column :workflows, :scufl, :binary, :limit => 1073741824
    add_column :workflow_versions, :scufl, :binary, :limit => 1073741824

    execute 'UPDATE workflows,content_blobs SET workflows.scufl = content_blobs.data WHERE workflows.content_blob_id = content_blobs.id'
    execute 'UPDATE workflow_versions,content_blobs SET workflow_versions.scufl = content_blobs.data WHERE workflow_versions.content_blob_id = content_blobs.id'

    Workflow.find(:all).each do |w|
      w.versions.each do |wv|
        wv.content_blob.destroy
      end
    end

    ActiveRecord::Base.record_timestamps = true
  end
end
