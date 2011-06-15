# myExperiment: vendor/plugins/structured_data/lib/structured_data.rb
#
# Copyright (c) 2009 University of Manchester and the University of Southampton.
# See license.txt for details.

module StructuredData

  module ActsMethods
    def acts_as_structured_data(opts = {})

      class_name = self.name

      class_name = opts[:class_name] if opts[:class_name]

      tables, associations = AutoMigrate.schema

      associations.each do |association|

        next unless association[:table].singularize.camelize == class_name

        case association[:type]
        when 'has_many'
          bits = [":#{association[:target]}"]

          bits.push(":through => :#{association[:through]}") if association[:through]
          bits.push(":foreign_key => :#{association[:foreign_key]}") if association[:foreign_key]
          bits.push(":source => :#{association[:source]}") if association[:source]
          bits.push(":dependent => :#{association[:dependent]}") if association[:dependent]
          bits.push(":conditions => \"#{association[:conditions]}\"") if association[:conditions]
          bits.push(":class_name => \"#{association[:class_name]}\"") if association[:class_name]
          bits.push(":as => :#{association[:as]}") if association[:as]

          line = "has_many #{bits.join(', ')}"
          self.class_eval(line)

        when 'belongs_to'
          bits = [":#{association[:target].singularize}"]

          bits.push(":polymorphic => #{association[:polymorphic]}") if association[:polymorphic]
          bits.push(":class_name => \"#{association[:class_name]}\"") if association[:class_name]
          bits.push(":foreign_key => :#{association[:foreign_key]}") if association[:foreign_key]

          line = "belongs_to #{bits.join(', ')}"
          self.class_eval(line)
        end
      end
    end
  end
end

