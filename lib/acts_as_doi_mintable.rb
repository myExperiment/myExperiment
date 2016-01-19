# myExperiment: lib/acts_as_doi_mintable.rb
#
# Copyright (c) 2015 University of Manchester and the University of Southampton.
# See license.txt for details.

require 'libxml'

module Finn
  module Acts #:nodoc:
    module DoiMintable #:nodoc:
      def self.included(mod)
        mod.extend(ClassMethods)
      end

      module ClassMethods
        def acts_as_doi_mintable(type_prefix, general_type = nil, options = {})
          cattr_accessor :doi_type_prefix, :datacite_resource_type_general, :datacite_resource_type

          self.doi_type_prefix = type_prefix
          self.datacite_resource_type_general = general_type

          # validate :has_doi?

          include Finn::Acts::DoiMintable::InstanceMethods
          # To generate resource's URL
          include Rails.application.routes.url_helpers
        end
      end

      module InstanceMethods
        def mint_doi(version = nil)
          if !version && self.respond_to?(:versioned_resource)
            version = self.version
          end

          unless self.doi.blank?
            errors.add(:doi, "already minted")
            return false
          end

          doi = generate_doi(version)
          metadata_xml = generate_datacite_metadata(doi)

          base_uri = URI(Conf.base_uri)
          if self.respond_to?(:versioned_resource)
            url = polymorphic_url(self.versioned_resource, :version => version, :host => base_uri.host)
          else
            if version
              url = polymorphic_url(self, :version => version, :host => base_uri.host)
            else
              url = polymorphic_url(self, :host => base_uri.host)
            end
          end

          resp = DataciteClient.instance.upload_metadata(metadata_xml)
          unless resp[0...2] == 'OK'
            raise "Error uploading metadata to datacite: #{resp}"
          end

          resp = DataciteClient.instance.mint(doi, url)
          unless resp[0...2] == 'OK'
            raise "Error minting DOI: #{resp}"
          end

          self.doi = doi
          self.save
        end

        private

        def generate_datacite_metadata(doi)
          if self.respond_to?(:versioned_resource)
            creators = self.versioned_resource.creditations(:include => :creditor)
          else
            creators = self.creditations(:include => :creditor)
          end
          creators = creators.select {|c| c.creditor_type == 'User'}.map(&:creditor)
          creators |= [self.contributor]

          # Need to know family name, given name for every user, or datacite will complain
          creators.each do |u|
            if u.family_name.blank? || u.given_name.blank?
              raise "#{u.name} has not set given name and/or family name in profile"
            end
          end

          doc = XML::Document.new
          root_node = XML::Node.new('resource')
          root_node["xsi:schemaLocation"] = "http://datacite.org/schema/kernel-3 http://schema.datacite.org/meta/kernel-3/metadata.xsd"
          root_node["xmlns"] = "http://datacite.org/schema/kernel-3"
          root_node["xmlns:xsi"] = "http://www.w3.org/2001/XMLSchema-instance"
          doc.root = root_node

          id_node = XML::Node.new('identifier')
          id_node["identifierType"] = "DOI"
          id_node << doi
          doc.root << id_node

          creators_node = XML::Node.new('creators')
          creators.each do |creator|
            node = XML::Node.new('creator')
            node << XML::Node.new('creatorName', "#{creator.family_name}, #{creator.given_name}")
            creators_node << node
          end
          doc.root << creators_node

          titles_node = XML::Node.new('titles')
          title_node = XML::Node.new('title')
          title_node["xml:lang"] = "en-gb"
          title_node << self.title
          titles_node << title_node
          doc.root << titles_node

          publisher_node = XML::Node.new('publisher', Conf.site_name)
          doc.root << publisher_node

          year_node = XML::Node.new('publicationYear', Time.now.year.to_s)
          doc.root << year_node

          descriptions_node = XML::Node.new('descriptions')
          description_node = XML::Node.new('description')
          description_node["xml:lang"] = "en-gb"
          description_node["descriptionType"] = "Abstract"
          description_node << ActionView::Base.full_sanitizer.sanitize(self.body)
          descriptions_node << description_node
          doc.root << descriptions_node

          if self.class.datacite_resource_type_general
            content_type = []
            content_type << self.content_type.title if self.respond_to?(:content_type)
            content_type << (self.respond_to?(:versioned_resource) ? self.versioned_resource.class.name.titleize : self.class.name.titleize)
            type_node = XML::Node.new('resourceType')
            type_node["resourceTypeGeneral"] = self.class.datacite_resource_type_general
            type_node << content_type.join(' ')
            doc.root << type_node
          end

          doc.to_s
        end

        def generate_doi(version = nil)
          if self.respond_to?(:versioned_resource)
            resource = self.versioned_resource
            version = self.version
          else
            resource = self
          end

          "#{Conf.doi_prefix}#{self.class.doi_type_prefix}/#{resource.id}#{(version ? (".#{version}") : '')}"
        end

        def has_doi?
          if self.doi
            errors.add_to_base("Unable to modify resource with DOI")
            return false
          end

          true
        end
      end
    end
  end
end

ActiveRecord::Base.class_eval do
  include Finn::Acts::DoiMintable
end
