class AddLicenseIdToWorkflowsAndBlobs < ActiveRecord::Migration
  def self.up
    #Need to rename columns so that license method and license field do not get confused
    rename_column :workflows, :license, :license_name
    rename_column :blobs, :license, :license_name
    
    add_column :workflows, :license_id, :integer, :default => nil
    add_column :blobs, :license_id, :integer, :default => nil
    
    Workflow.find(:all).each do |w|
      execute("UPDATE workflows SET license_id = #{License.find(:first,:conditions=>[ 'unique_name = ?', w.license_name ]).id } WHERE id = #{w.id}")
    end
    Blob.find(:all).each do |b|
      execute("UPDATE blobs SET license_id = #{License.find(:first,:conditions=>[ 'unique_name = ?', b.license_name ]).id } WHERE id = #{b.id}")
    end 
    remove_column :workflows, :license_name
    remove_column :blobs, :license_name
  end
  
  def self.down
    add_column :workflows, :license, :string, 
               :limit => 10, :null => false, 
               :default => "by-sa"
               
    add_column :blobs, :license, :string, 
               :limit => 10, :null => false, 
               :default => "by-sa"
    Workflow.find(:all).each do |w|
      execute("UPDATE workflows SET license = '#{License.find(w.license_id).unique_name }' WHERE id = #{w.id}")
    end
    Blob.find(:all).each do |b|
      execute("UPDATE blobs SET license = '#{License.find(b.license_id).unique_name }' WHERE id = #{b.id}")
    end
    remove_column :workflows, :license_id
    remove_column :blobs, :license_id
  end
end