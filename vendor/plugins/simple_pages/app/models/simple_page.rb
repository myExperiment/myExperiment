class SimplePage < ActiveRecord::Base

  # make sure to install the acts_as_versioned plugin to make simple_pages revisioning work!
  #  $ ruby script/plugin source http://svn.techno-weenie.net/projects/plugins
  #  $ ruby script/plugin install -x acts_as_versioned
  acts_as_versioned if respond_to?(:acts_as_versioned)

  validates_presence_of   :filename, :title
  validates_uniqueness_of :filename, :title
  
  before_save :fix_filename
  
  # Page#to_param is used to fill the :id portion of the request.  This gives us pretty urls.
  def to_param
    self.filename
  end

  # make lowercase and underscored
  def fix_filename
    self.filename = filename.downcase.gsub(' ', '-')
  end
  
end