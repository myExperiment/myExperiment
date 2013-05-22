
class AnnotationResource < ActiveRecord::Base
  belongs_to :annotation, :class_name => "Resource"
end

