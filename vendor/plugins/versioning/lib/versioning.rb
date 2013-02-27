# myExperiment: vendor/plugins/versioning/lib/versioning.rb
#
# Copyright (c) 2011 University of Manchester and the University of Southampton.
# See license.txt for details.

module Versioning

  module ActsMethods

    def has_versions(version_class, opts = {})

      cattr_accessor :version_class, :versioned_attributes, :mutable_attributes, :versioned_resource_column

      attr_accessor :inhibit_version_check
      attr_accessor :new_version_number

      self.version_class             = version_class.to_s.camelize.singularize.constantize
      self.versioned_attributes      = opts[:attributes]                || []
      self.mutable_attributes        = opts[:mutable]                   || []
      self.versioned_resource_column = opts[:versioned_resource_column] || "#{self.table_name.singularize}_id"

      inhibit_version_check = false

      class_eval do

        has_many :versions, :class_name => self.version_class.name, :dependent => :destroy

        def find_version(v)
          match = self.version_class.find(:first, :conditions => ["#{self.versioned_resource_column} = ? AND version = ?", id, v])
          return match if match

          raise ActiveRecord::RecordNotFound.new("Couldn't find #{self.version_class.name} with #{self.versioned_resource_column}=#{id} and version=#{v}")
        end

        def changed_versioned_attributes
          versioned_attributes.select do |attr|
            if respond_to?(attr)
              changes[attr.to_s] || (send(attr).respond_to?(:changed) && send(attr).changed?)
            end
          end
        end

        # If this is a new record or a versioned attribute has changed that is
        # not marked as mutable, then this will be a new version.

        def new_version?
          new_record? || (changed_versioned_attributes - mutable_attributes).length > 0
        end

        def describe_version(version_number)
          return "" if versions.count < 2
          return "(earliest)" if version_number == versions.first.version
          return "(latest)" if version_number == versions.last.version
          return ""
        end
      end

      before_save do |resource|

        unless resource.inhibit_version_check

          if resource.new_version?

            new_version = resource.version_class.new

            resource.current_version = resource.current_version ? resource.current_version + 1 : 1
            new_version[:version] = resource.current_version
            resource.new_version_number = resource.current_version

            resource.versioned_attributes.each do |attr|
              if new_version.respond_to?("#{attr}=") && resource.respond_to?(attr)
                new_version.send("#{attr}=", resource.send(attr))
              end
            end

            resource.versions << new_version

          else

            changed_attributes = resource.changed_versioned_attributes
            
            if !changed_attributes.empty?

              # A new version wasn't created, but some attributes in the latest
              # version need updating.

              version = resource.find_version(resource.current_version)

              changed_attributes.each do |attr|
                version[attr] = resource[attr]
              end

              version.save
            end
          end
        end
      end
    end

    def is_version_of(versioned_resource_class_name, opts = {})

      cattr_accessor :versioned_resource_class_name

      attr_accessor :inhibit_version_check

      self.versioned_resource_class_name = versioned_resource_class_name

      inhibit_version_check = false

      class_eval do
        versioned_resource_class_name
        belongs_to self.versioned_resource_class_name
        alias_method :versioned_resource, self.versioned_resource_class_name
      end

      validate do |version|

        if !version.new_record?

          resource_class = self.versioned_resource_class_name.to_s.camelize.constantize

          immutable_attributes = resource_class.versioned_attributes - resource_class.mutable_attributes
          changed_attributes   = version.changes.keys.map do |attr| attr.to_sym end
          blocking_attributes  = immutable_attributes & changed_attributes

          blocking_attributes.each do |attr|
            version.errors.add(attr, 'is immutable')
          end
        end
      end
      
      after_save do |version|

        unless version.inhibit_version_check

          versioned_resource = version.versioned_resource

          if version.version == versioned_resource.current_version

            versioned_resource.versioned_attributes.each do |attr|
              if versioned_resource.respond_to?("#{attr}=") && version.respond_to?(attr)
                versioned_resource.send("#{attr}=", version.send(attr))
              end
            end

            versioned_resource.inhibit_version_check = true
            versioned_resource.save
            versioned_resource.inhibit_version_check = false
          end
        end
      end
    end
  end
end

