# myExperiment: app/models/workflow_version.rb
#
# Copyright (c) 2012 University of Manchester and the University of Southampton.
# See license.txt for details.

require 'lib/previews'

class WorkflowVersion < ActiveRecord::Base

  is_version_of :workflow

  format_attribute :body

  belongs_to :content_blob, :dependent => :destroy
  belongs_to :content_type

  validates_presence_of :content_blob
  validates_presence_of :content_type
  
  # Update the parent contribution model buy only if this isn't the current version (because the workflow model will take care of that).
  # This is required to keep the contribution's updated_at field accurate.
  after_save { |wv| wv.workflow.contribution.save if wv.workflow.contribution && wv.version != wv.workflow.current_version }

  has_previews

  def components
    if processor_class
      processor_class.new(content_blob.data).get_components
    else
      XML::Node.new('components')
    end
  end

  def processor_class
    if self.content_type
      @processor_class ||= WorkflowTypesHandler.processor_class_for_type_display_name(self.content_type.title)
    end
  end

  def display_data_format
    klass = self.processor_class
    @display_data_format = (klass.nil? ? self.file_ext : klass.display_data_format)
  end

  def can_infer_title?
    if processor_class
      processor_class.can_infer_title?
    else
      false
    end
  end

  def can_infer_description?
    if processor_class
      processor_class.can_infer_description?
    else
      false
    end
  end

  def can_generate_preview_image?
    if processor_class
      processor_class.can_generate_preview_image?
    else
      false
    end
  end
end

