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

          line = "has_many #{bits.join(', ')}"
          self.class_eval(line)

        when 'belongs_to'
          bits = [":#{association[:target].singularize}"]

          bits.push(":polymorphic => #{association[:polymorphic]}") if association[:polymorphic]

          line = "belongs_to #{bits.join(', ')}"
          self.class_eval(line)
        end
      end
    end
  end
end

