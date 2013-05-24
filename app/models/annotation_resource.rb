
class AnnotationResource < ActiveRecord::Base
  belongs_to :annotation, :class_name => "Resource"
  belongs_to :research_object
end

