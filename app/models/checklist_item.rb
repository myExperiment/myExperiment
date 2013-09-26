# myExperiment: app/models/checklist_item_result.rb
#
# Copyright (c) 2007-2013 The University of Manchester, the University of
# Oxford, and the University of Southampton.  See license.txt for details.

class ChecklistItem < ActiveRecord::Base

  belongs_to :checklist

end

