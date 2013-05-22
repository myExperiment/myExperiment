# myExperiment: db/migrate/084_assign_categories_to_content_types.rb
#
# Copyright (c) 2010 University of Manchester and the University of Southampton.
# See license.txt for details.

class AssignCategoriesToContentTypes < ActiveRecord::Migration
  def self.up
    workflow_content_types = Workflow.find(:all).group_by do |w| w.content_type_id end.keys

    ContentType.find(:all).each do |content_type|
      if workflow_content_types.include?(content_type.id)
        category = "Workflow"
      else
        category = "Blob"
      end

      content_type.update_attribute("category", category)
    end
  end

  def self.down
  end
end
