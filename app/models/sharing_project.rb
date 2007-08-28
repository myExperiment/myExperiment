class SharingProject < ActiveRecord::Base
  belongs_to :workflow
  belongs_to :project
end
