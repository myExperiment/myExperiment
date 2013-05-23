# myExperiment: lib/acts_as_rdf_serializable.rb
#
# Copyright (c) 2013 University of Manchester and the University of Southampton.
# See license.txt for details.

module Finn
  module Acts #:nodoc:
    module RDFSerializable #:nodoc:

      def self.included(mod)
        mod.extend(ClassMethods)
      end

      module ClassMethods

        ##
        # Specify an representation of the resource as a string (in the specified :format:)
        #  in the block (to which the resource instance is yielded).
        # The resource will be stored in TripleStore on save/update, and removed when deleted.
        def acts_as_rdf_serializable(format, options = {}, &block)
          cattr_accessor :rdf_generator, :rdf_format, :rdf_serializable_options

          self.rdf_serializable_options = options
          self.rdf_generator = block
          self.rdf_format = format

          validate :generate_rdf

          after_save :store_rdf
          after_destroy :destroy_rdf

          include Finn::Acts::RDFSerializable::InstanceMethods
          # To generate resource's URI to be used as "context" in the triple store:
          include ActionController::UrlWriter
          include ActionController::PolymorphicRoutes
        end
      end

      module InstanceMethods

        def to_rdf
          self.class.rdf_generator.call(self)
        end

        private

        def resource_uri
          base_uri = URI(Conf.base_uri)
          "<#{polymorphic_url(self, :host => "#{base_uri.host}:#{base_uri.port}")}>"
        end

        def generate_rdf
          begin
            @rdf = self.to_rdf
          rescue
            raise unless Rails.env == "production"
            errors.add_to_base(self.rdf_serializable_options[:generation_error_message] || "RDF failed to generate")
            false
          else
            true
          end
        end

        def store_rdf
          unless TripleStore.instance.nil? || @rdf.nil?
            TripleStore.instance.insert(@rdf, resource_uri, self.class.rdf_format)
          end
        end

        def destroy_rdf
          unless TripleStore.instance.nil?
            TripleStore.instance.delete(:context => resource_uri)
          end
        end
      end
    end
  end
end

ActiveRecord::Base.class_eval do
  include Finn::Acts::RDFSerializable
end
