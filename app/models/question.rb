require 'acts_as_contributable'
require 'acts_as_creditable'
require 'acts_as_attributor'
require 'acts_as_attributable'

class Question < ActiveRecord::Base

  acts_as_contributable
  
  acts_as_creditable

  acts_as_attributor
  acts_as_attributable

  acts_as_solr(:fields => [ :title, :tag_list, :contributor_name ],
               :include => [ :comments ]) if SOLR_ENABLE

  validates_presence_of :title
  
  def contributor_name
    case contribution.contributor.class.to_s
    when "User"
      return contribution.contributor.name
    when "Network"
      return contribution.contributor.title
    else
      return nil
    end
  end
  
  def tag_list_comma
    list = ''
    tags.each do |t|
      if list == ''
        list = t.name
      else
        list += (", " + t.name)
      end
    end
    return list
  end
  
end