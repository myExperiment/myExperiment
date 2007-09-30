class Citation < ActiveRecord::Base
  belongs_to :user
  belongs_to :workflow
  
  validates_presence_of :user_id, :workflow_id, :workflow_version, :authors, :title, :published_at
  
  validates_numericality_of :workflow_version
  validates_numericality_of :isbn, :if => Proc.new { |c| !(c.isbn.nil? or c.isbn.empty?) }
  validates_numericality_of :issn, :if => Proc.new { |c| !(c.issn.nil? or c.issn.empty?) }
  
  validates_each :isbn, :if => Proc.new { |c| !(c.isbn.nil? or c.isbn.empty?) } do |record, attr, value|
    record.errors.add :isbn, "is the wrong length (should be 10 or 13 characters)" unless value.length.to_i == 10 or value.length.to_i == 13
  end
  
  validates_length_of :issn, :is => 8, :if => Proc.new { |c| !(c.issn.nil? or c.issn.empty?) }
end
