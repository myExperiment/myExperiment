# myExperiment: app/models/workflow.rb
#
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

require 'acts_as_site_entity'
require 'acts_as_contributable'
require 'acts_as_creditable'
require 'acts_as_attributor'
require 'acts_as_attributable'
require 'acts_as_reviewable'
require 'acts_as_runnable'
require 'acts_as_rdf_serializable'
require 'previews'
require 'sunspot_rails'

require 'scufl/model'
require 'scufl/parser'

require 'has_research_object'

class Workflow < ActiveRecord::Base
  
  include ResearchObjectsHelper

  has_many :citations, 
           :order => "created_at DESC",
           :dependent => :destroy

  belongs_to :content_blob, :dependent => :destroy
  belongs_to :content_type
  belongs_to :license

  has_many :workflow_processors, :dependent => :destroy
  has_many :workflow_ports, :dependent => :destroy
  has_many :semantic_annotations, :as => :subject, :dependent => :destroy

  before_validation :check_unique_name
  before_validation :apply_extracted_metadata

  acts_as_site_entity :owner_text => 'Original Uploader'

  acts_as_contributable
  
  acts_as_bookmarkable
  acts_as_commentable
  acts_as_rateable
  acts_as_taggable

  acts_as_creditable

  acts_as_attributor
  acts_as_attributable
  
  acts_as_reviewable

  acts_as_rdf_serializable('application/x-turtle',
      :generation_error_message => "Failed to generate RDF, please check the given workflow file is valid.") do |workflow|
    workflow.processor_class.new(workflow.content_blob.data).extract_rdf_structure(workflow) unless workflow.processor_class.nil?
  end

  has_previews

  has_versions :workflow_versions,
  
    :attributes => [ :contributor, :title, :unique_name, :body, :body_html,
                     :content_blob_id, :file_ext, :last_edited_by,
                     :content_type_id, :preview_id, :image, :svg,
                     :revision_comments],

    :mutable => [ :contributor, :title, :unique_name, :body, :body_html,
                  :file_ext, :last_edited_by, :content_type_id, :image, :svg ]

  if Conf.solr_enable
    searchable do

      text :title, :as => 'title', :boost => 2.0
      text :body, :as => 'description'
      text :filename, :as => 'file_name'
      text :contributor_name, :as => 'contributor_name'
      text :kind, :as => 'kind'
      text :get_all_search_terms

      text :tags, :as => 'tag' do
        tags.map { |tag| tag.name }
      end

      text :comments, :as => 'comment' do
        comments.map { |comment| comment.comment }
      end

      text :review_titles, :as => 'review_title' do
        reviews.map { |review| review.title }
      end

      text :review_bodies, :as => 'review_body' do
        reviews.map { |review| review.review }
      end
    end
  end

  acts_as_runnable
  
  validates_presence_of :title
  
  format_attribute :body
  
  validates_presence_of :unique_name
  validates_uniqueness_of :unique_name
  
  validates_presence_of :content_blob
  validates_presence_of :content_type

  has_research_object
  
  after_create :create_research_object

  def tag_list_comma
    list = ''
    tags.each do |t|
      if list == ''
        list = t.name
      else
        list += (", " + t.name)
      end
    end
    return list
  end
  
  def check_unique_name
    set_unique_name if unique_name.nil?
  end

  # Sets an internal unique name for this workflow.
  def set_unique_name
    salt = rand 1000000
    salt2 = rand 100
    if self.title.blank?
      self.unique_name = "#{salt}_#{salt2}"        
    else
      self.unique_name = "#{self.title.gsub(/[^\w\.\-]/,'_').downcase}_#{salt}"
    end
  end
  
  def self.extract_metadata(opts = {})

    if opts[:type]
      content_type = ContentType.find_by_title(opts[:type])
    elsif opts[:mime_type]
      content_type = ContentType.find_by_mime_type(opts[:mime_type])
    end

    if content_type
      proc_class = WorkflowTypesHandler.processor_class_for_type_display_name(content_type.title)
    end

    metadata = {}

    if proc_class && opts[:data]

      processor = proc_class.new(opts[:data])

      metadata["title"]       = processor.get_title
      metadata["description"] = processor.get_description

      if proc_class.can_generate_preview_image?
        metadata["image"] = processor.get_preview_image
      end

      if proc_class.can_generate_preview_svg?
        metadata["svg"] = processor.get_preview_svg
      end
    end

    metadata
  end

  # This method is called before validation and attempts to pull out metadata if it
  # hasn't been set

  def apply_extracted_metadata

    return if content_blob.nil? or content_type.nil?

    metadata = Workflow.extract_metadata(:type => content_type.title, :data => content_blob.data)

    self.title = metadata["title"]       if metadata["title"]       and title.nil?
    self.body  = metadata["description"] if metadata["description"] and body.nil?
    self.image = metadata["image"]       if metadata["image"]       and image.nil?
    self.svg   = metadata["svg"]         if metadata["svg"]         and svg.nil?
  end

  def processor_class
    if self.content_type
      @processor_class ||= WorkflowTypesHandler.processor_class_for_type_display_name(self.content_type.title)
    end
  end
  
  def can_infer_metadata_for_this_type?
    proc_class = self.processor_class
    return false if proc_class.nil?
    return proc_class.can_infer_metadata?
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

  def type_display_name
    content_type.title
  end
  
  def display_data_format
    klass = self.processor_class
    @display_data_format = (klass.nil? ? self.file_ext : klass.display_data_format)
  end
  
  def get_workflow_processor(version = current_version)

    return nil unless workflow_version = self.find_version(version)
    return nil unless version_processor = workflow_version.processor_class

    version_processor.new(workflow_version.content_blob.data)
  end

  def get_workflow_model_object(version)

    return nil unless version_processor = get_workflow_processor(version)

    version_processor.get_workflow_model_object
  end

  def get_search_terms(version)

    return nil unless version_processor = get_workflow_processor(version)

    version_processor.get_search_terms
  end

  # Begin acts_as_runnable overridden methods
 
  def get_input_ports(version)

    return nil unless version_processor = get_workflow_processor(version)

    return version_processor.get_workflow_model_input_ports
  end
  
  # End acts_as_runnable overridden methods

  def filename_aux(record)

    extension = ""

    if record.processor_class && record.processor_class.default_file_extension
      extension = ".#{record.processor_class.default_file_extension}"
    end

    if record.file_ext
      extension = ".#{record.file_ext}"
    end

    extension
  end

  def filename(version=nil)

    if version.blank?
      "#{unique_name}#{filename_aux(self)}"
    else
      workflow_version = self.find_version(version)
      "#{workflow_version.unique_name}#{filename_aux(workflow_version)}"
    end
  end
  
  def named_download_url(version = nil)
    "#{Conf.base_uri}/workflows/#{id}/download/#{filename(version)}"
  end

  def get_all_search_terms

    begin
      words = StringIO.new

      versions.each do |version|
        words << get_search_terms(version.version)
      end

      words.rewind
      words.read
    rescue
      nil
    end
  end

  def get_tag_suggestions()

    ignore = [ "and", "the", "or", "a", "an" ]
    
    text = "#{title} #{body} #{get_search_terms(current_version)}"

    words = text.split(/[^a-zA-Z0-9]+/).uniq

    all_tags = Tag.find(:all).select do |t| t.taggings_count > 0 end.map do |t| t.name end

    candidates = words - (words - all_tags)

    candidates = candidates - ignore

    existing = tags.map do |t| t.name end

    (candidates - existing).sort
  end

  def components
    if processor_class
      begin
        processor_class.new(content_blob.data).get_components
      rescue
        XML::Node.new('components')
      end
    else
      XML::Node.new('components')
    end
  end

  def type
    content_type.title
  end

  alias_method :kind, :type

  def rank

    boost = 0

    # initial boost depends on viewings count
    boost = contribution.viewings_count / 100 if contribution

    # Take curation events into account
    boost += CurationEvent.curation_score(CurationEvent.find_all_by_object_type_and_object_id('Workflow', id))
    
    # penalty for no description
    boost -= 20 if body.nil? || body.empty?
    
    boost
  end

  def show_download_section?
    if processor_class
      processor_class.show_download_section?
    else
      true
    end
  end

  def delete_metadata
    if processor_class
      WorkflowProcessor.destroy_all(["workflow_id = ?", id])
      WorkflowPort.destroy_all(["workflow_id = ?", id])
    end
  end

  def extract_metadata
    if processor_class
      delete_metadata
      begin
        processor_class.new(content_blob.data).extract_metadata(self)
      rescue
        raise unless Rails.env == 'production'
      end
    end
  end
  
  def unique_wsdls
    WorkflowProcessor.find(:all,
                           :conditions => ['workflow_id = ? AND wsdl IS NOT NULL', id]).map do |wp| wp.wsdl end.uniq
  end

  def workflows_with_similar_services

    # Get the WSDL URIs that this workflow uses

    workflow_wps = WorkflowProcessor.find(:all,
        :select     => 'DISTINCT workflow_id, wsdl',
        :conditions => ['workflow_id = ? AND wsdl IS NOT NULL', id])

    return [] if workflow_wps.empty?

    wsdls = workflow_wps.map do |wp| wp.wsdl end

    # Get all the related workflows

    related_wps = WorkflowProcessor.find(:all,
        :select => 'DISTINCT workflow_id, wsdl',
        :conditions => ['workflow_id != ? AND (' + ((1..wsdls.length).map do "wsdl = ?" end).join(" OR ") + ')', id] + wsdls)

    related_workflows = related_wps.group_by do |wp| wp.workflow end

    # Sort results based on the number of matching services with the original workflow

    related_workflows = related_workflows.sort do |a, b| b[1].length <=> a[1].length end

    related_workflows.map do |result| result[0] end
  end

  def statistics_for_rest_api
    APIStatistics.statistics(self)
  end

  # Returns a hash map of lists of wsdls grouped by their related deprecation event
  def deprecations
    WsdlDeprecation.find_all_by_wsdl(workflow_processors.map {|wp| wp.wsdl}).group_by {|wd| wd.deprecation_event}
  end

  def create_research_object

    user_path = "/users/#{contributor_id}"

    slug = "Workflow#{self.id}"
    slug = SecureRandom.uuid if ResearchObject.find_by_slug_and_version(slug, nil)

    ro = ResearchObject.create(:slug => slug, :user => self.contributor)
    
    update_attribute(:research_object, ro)

    workflow_resource = ro.create_aggregated_resource(
        :user_uri     => user_path,
        :path         => filename,  # FIXME - where should these be URL encoded?
        :data         => content_blob.data,
        :context      => self,
        :content_type => content_type.mime_type)
  end
end
