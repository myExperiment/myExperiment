# myExperiment: lib/acts_as_doi_mintable.rb
#
# Copyright (c) 2015 University of Manchester and the University of Southampton.
# See license.txt for details.

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
          # To generate resource's URI to be used as "context" in the triple store:
          include ActionController::UrlWriter
          include ActionController::PolymorphicRoutes
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
          metadata_xml = generate_datacite_metadata

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

          client = DataciteClient.instance

          resp = client.upload_metadata(metadata_xml)
          unless resp[0...2] == 'OK'
            raise "Error uploading metadata to datacite: #{resp}"
          end

          resp = client.mint(doi, url)
          unless resp[0...2] == 'OK'
            raise "Error minting DOI: #{resp}"
          end

          self.doi = doi
          self.save
        end

        private

        def generate_datacite_metadata
          if self.respond_to?(:versioned_resource)
            credits = self.versioned_resource.creditations(:include => :creditor)
          else
            credits = self.creditations(:include => :creditor)
          end
          credits = credits.select {|c| c.creditor_type == 'User'}.map(&:creditor)
          credits |= [self.contributor]

          authors = credits.map do |u|
            unless u.family_name.blank? || u.given_name.blank?
              "<creator><creatorName>#{u.family_name}, #{u.given_name}</creatorName></creator>"
            else
              raise "#{u.name} has not set given name and/or family name in profile"
            end
          end.join

          type = ''

          if self.class.datacite_resource_type_general
            content_type = "#{self.content_type.title} #{self.respond_to?(:versioned_resource) ? self.versioned_resource.class.name.titleize : self.class.name.titleize}"
            type = %(<resourceType resourceTypeGeneral="#{self.class.datacite_resource_type_general}">#{content_type}</resourceType>)
          end

%(<?xml version="1.0" encoding="UTF-8"?>
<resource xsi:schemaLocation="http://datacite.org/schema/kernel-3 http://schema.datacite.org/meta/kernel-3/metadata.xsd" xmlns="http://datacite.org/schema/kernel-3" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
    <identifier identifierType="DOI">#{doi}</identifier>
    <creators>
      #{authors}
    </creators>
    <titles>
        <title xml:lang="en-gb">#{self.title}</title>
    </titles>
    <publisher>myExperiment</publisher>
    <publicationYear>#{Time.now.year}</publicationYear>
    #{type}
    <descriptions>
        <description xml:lang="en-gb" descriptionType="Abstract">
            #{self.body}
        </description>
    </descriptions>
</resource>
)
        end

        def generate_doi(version = nil)
          "#{Conf.doi_prefix}/#{self.class.doi_type_prefix}/#{self.id}#{(version ? (".#{version}") : '')}"
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
