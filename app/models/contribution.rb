# myExperiment: app/models/contribution.rb
#
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

class Contribution < ActiveRecord::Base
  belongs_to :contributor, :polymorphic => true
  belongs_to :contributable, :polymorphic => true
  belongs_to :policy
  
  has_many :downloads,
           :order => "created_at DESC",
           :dependent => :destroy
           
  has_many :viewings,
           :order => "created_at DESC",
           :dependent => :destroy

  def self.contributions_list(klass = nil, params = nil, user = nil)

    sort_options = Conf.contribution_order_options

    args = sort_options.first

    sort_options.each do |sort_option|
      args = sort_option if params["order"] == sort_option["option"]
    end
    
    num    = 10
    offset = 0

    if params["page"]
      offset = (params["page"].to_i - 1) * num
    end

    # This uses the proprietary MySQL feature "SQL_CALC_FOUND_ROWS" to
    # determine the total number of rows if it weren't for the LIMIT clause

    results = Authorization.authorised_index(:type => klass,
        :select => 'SQL_CALC_FOUND_ROWS contributions.*',
        :user => user,
        :contribution_records => true,
        :limit => "#{offset}, #{num}",
        :joins => args["joins"],
        :order => args["order"])

    total = ActiveRecord::Base.connection.execute("SELECT FOUND_ROWS()").fetch_row.first.to_i

    PaginatedArray.new(results, :total => total, :limit => num, :offset => offset)
  end

  # returns the 'most downloaded' Contributions
  # (only takes into account downloads, that is internal usage)
  # the maximum number of results is set by #limit#
  def self.most_downloaded(limit=10, klass=nil)
    if klass
      type_condition = "c.contributable_type = '#{klass}' AND"
    else
      type_condition = ""
    end
    
    self.find_by_sql("SELECT c.* FROM contributions c LEFT JOIN downloads d ON c.id = d.contribution_id WHERE #{type_condition} d.accessed_from_site = 1 GROUP BY d.contribution_id ORDER BY COUNT(d.contribution_id) DESC LIMIT #{limit}")
  end
  
  # returns the 'most viewed' Contributions
  # (only takes into account viewings, that is internal usage)
  # the maximum number of results is set by #limit#
  def self.most_viewed(limit=10, klass=nil)
    if klass
      type_condition = "c.contributable_type = '#{klass}' AND"
    else
      type_condition = ""
    end
    
    self.find_by_sql("SELECT c.* FROM contributions c LEFT JOIN viewings v ON c.id = v.contribution_id WHERE #{type_condition} v.accessed_from_site = 1 GROUP BY v.contribution_id ORDER BY COUNT(v.contribution_id) DESC LIMIT #{limit}")
  end
  
  # returns the 'most recent' Contributions
  # the maximum number of results is set by #limit#
  def self.most_recent(limit=10, klass=nil)
    Authorization.authorised_index(:type => klass ? Object.const_get(klass) : nil, :contribution_records => true, :limit => limit, :order => 'created_at DESC')
  end
  
  # returns the 'last updated' Contributions
  # the maximum number of results is set by #limit#
  def self.last_updated(limit=10, klass=nil)
    Authorization.authorised_index(:type => klass ? Object.const_get(klass) : nil, :contribution_records => true, :limit => limit, :order => 'updated_at DESC')
  end
  
  # returns the 'most favourited' Contributions
  # the maximum number of results is set by #limit#
  def self.most_favourited(limit=10, klass=nil)
    if klass
      type_condition = "WHERE c.contributable_type = '#{klass}'"
    else
      type_condition = ""
    end
    
    self.find_by_sql("SELECT c.*, COUNT(b.bookmarkable_id) AS cnt FROM contributions c JOIN bookmarks b ON c.contributable_type = b.bookmarkable_type AND c.contributable_id = b.bookmarkable_id #{type_condition} GROUP BY b.bookmarkable_id ORDER BY cnt DESC LIMIT #{limit}")
  end
  
  # is c_utor authorized to edit the policy for this contribution
  def admin?(c_utor)
    #policy.contributor_id.to_i == c_utor.id.to_i and policy.contributor_type.to_s == c_utor.class.to_s
    policy.admin?(c_utor)
  end
  
  # is c_utor the owner of this contribution
  def owner?(c_utor)
    #contributor_id.to_i == c_utor.id.to_i and contributor_type.to_s == c_utor.class.to_s
    
    case self.contributor_type.to_s
    when "User"
      return (self.contributor_id.to_i == c_utor.id.to_i and self.contributor_type.to_s == c_utor.class.to_s)
    when "Network"
      return self.contributor.owner?(c_utor.id) if self.contributor_type.to_s
    else
      return false
    end
    
    #return (self.contributor_id.to_i == c_utor.id.to_i and self.contributor_type.to_s == c_utor.class.to_s) if self.contributor_type.to_s == "User"
    #return self.contributor.owner?(c_utor.id) if self.contributor_type.to_s == "Network"
    
    #false
  end
  
  # is c_utor the original uploader of this contribution
  def uploader?(c_utor)
    #contributable.contributor_id.to_i == c_utor.id.to_i and contributable.contributor_type.to_s == c_utor.class.to_s
    contributable.uploader?(c_utor)
  end
  
  def shared_with_networks
    networks = []
    self.policy.permissions.each do |p|
      if p.contributor_type == 'Network'
        networks << p.contributor
      end
    end
    networks
  end
end
