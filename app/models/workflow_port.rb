class WorkflowPort < ActiveRecord::Base
  validates_inclusion_of :port_type, :in => ["input", "output"]
  belongs_to :workflow
  has_many :semantic_annotations, :as => :subject, :dependent => :destroy
end
