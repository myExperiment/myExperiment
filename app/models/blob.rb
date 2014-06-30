# myExperiment: app/models/blob.rb
#
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

require 'acts_as_contributable'
require 'acts_as_site_entity'
require 'acts_as_creditable'
require 'acts_as_attributor'
require 'acts_as_attributable'
require 'sunspot_rails'

require 'has_research_object'

class Blob < ActiveRecord::Base

  include ResearchObjectsHelper

  acts_as_site_entity :owner_text => 'Uploader'

  acts_as_contributable

  acts_as_bookmarkable
  acts_as_commentable
  acts_as_rateable
  acts_as_taggable
  
  acts_as_creditable

  acts_as_attributor
  acts_as_attributable

  has_versions :blob_versions,

    :attributes => [ :title, :body, :body_html, :content_type, :content_blob,
                     :local_name ],

    :mutable => [ :title, :body, :body_html ]

  if Conf.solr_enable
    searchable do
      text :title, :as => 'title', :boost => 2.0
      text :local_name, :as => 'file_name'
      text :body, :as => 'description'
      text :kind, :as => 'kind'
      text :contributor_name, :as => 'contributor_name'

      text :tags, :as => 'tag' do
        tags.map { |tag| tag.name }
      end

      text :comments, :as => 'comment' do
        comments.map { |comment| comment.comment }
      end
    end
  end

  belongs_to :content_blob, :dependent => :destroy
  belongs_to :content_type
  belongs_to :license
 
  validates_presence_of :content_blob
  validates_presence_of :content_type

  validates_presence_of :title
  validates_presence_of :local_name

  validates_each :content_blob do |record, attr, value|
    if value.data.size > Conf.max_upload_size
      record.errors.add(:file, "is too big.  Maximum size is #{Conf.max_upload_size} bytes.")
    end
  end

  has_research_object

  after_create :create_research_object

  format_attribute :body

  def type
    content_type.title
  end

  alias_method :kind, :type

  def rank

    boost = 0

    # initial boost depends on viewings count
    boost = contribution.viewings_count / 100 if contribution

    # Take curation events into account
    boost += CurationEvent.curation_score(CurationEvent.find_all_by_object_type_and_object_id('Blob', id))
    
    # penalty for no description
    boost -= 20 if body.nil? || body.empty?
    
    boost
  end

  def named_download_url
    "#{Conf.base_uri}/files/#{id}/download/#{local_name}"
  end

  def statistics_for_rest_api
    APIStatistics.statistics(self)
  end

  scope :component_profiles, :include => :content_type,
              :conditions => "content_types.mime_type = 'application/vnd.taverna.component-profile+xml'"

  def component_profile?
    content_type.mime_type == 'application/vnd.taverna.component-profile+xml'
  end

  def create_research_object

    user_path = "/users/#{contributor_id}"

    slug = "File#{self.id}"
    slug = SecureRandom.uuid if ResearchObject.find_by_slug_and_version(slug, nil)

    ro = build_research_object(:slug => slug, :user => self.contributor)
    ro.save

    file_resource = ro.create_aggregated_resource(
        :user_uri     => user_path,
        :path         => local_name,  # FIXME - where should these be URL encoded?
        :data         => content_blob.data,
        :context      => self,
        :content_type => content_type.mime_type)
  end
end
