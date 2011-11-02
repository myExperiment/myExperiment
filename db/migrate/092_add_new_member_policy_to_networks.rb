class AddNewMemberPolicyToNetworks < ActiveRecord::Migration
  def self.up
    add_column :networks, :new_member_policy, :string, :default => "open"

    Network.find(:all).each do |n|
      if n.attributes["auto_accept"] == true
        n.new_member_policy = :open
      else
        n.new_member_policy = :by_request
      end
      n.save
    end

    remove_column :networks, :auto_accept
  end

  #Will lose info on whether a network is invite only
  def self.down
    add_column :networks, :auto_accept, :boolean, :default => false

    Network.find(:all).each do |n|
      if n.attributes["new_member_policy"] == "open"
        n.auto_accept = true
      else
        n.auto_accept = false
      end
      n.save
    end

    remove_column :networks, :new_member_policy
  end
end
