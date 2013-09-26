# myExperiment: app/models/checklist_result.rb
#
# Copyright (c) 2007-2013 The University of Manchester, the University of
# Oxford, and the University of Southampton.  See license.txt for details.

class ChecklistResult < ActiveRecord::Base

  belongs_to :research_object

  has_many :checklist_item_results, :dependent => :destroy

end
