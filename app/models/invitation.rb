class Invitation
  
  # Validates a list of email addresses by:
  # trimming whitespace for each, applying a pre-defined regexp to check the structure,
  # eliminates duplicates in the list of emails, splits those in various classes.
  # 
  # Input: a comma- or semicolon- separated list of email addresses
  #  
  # Returns: array of 5 elements:
  # 1) total number of unique addresses at input
  # 2) number of successfully validated addresses that don't belong to any of the existing users
  # 3) array of valid addresses
  # 4) hash of pairs ("existing_db_address" -> user_id)
  # 5) array of erroneous addresses
  def self.validate_address_list (emails_csv_string, current_user)
    
    # calling code relies on the 'err_addresses' variable being initialized to [] at the beginning
    err_addresses = []
    valid_addresses = []
    db_user_addresses = {}
    
    addr_cnt = 0
    validated_addr_cnt = 0
    
    # splitting the string into array of emails
    emails = emails_csv_string.split(/[,;]/);
    
    # trimming all the whitespace in each email
    emails.length.times { |i|
      emails[i] = emails[i].strip
    }
    
    # chopping off duplicates, checking address for validity & sending mails
    # regexp taken from 'http://www.regular-expressions.info/email.html'
    emails.uniq.each { |email_addr|
      if !email_addr.blank?
        addr_cnt += 1
        
        if email_addr.downcase.match(/^[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,4}$/)
          # email_addr is validated if we are here;          

          # check if it is also present in the DB as registered address of some user -
          # if so, it needs to be treated differentrly
          if( u = User.find(:first, :conditions => ["email = ? OR unconfirmed_email = ?", email_addr, email_addr]) )
            db_user_addresses[email_addr] = u.id    
          else
            validated_addr_cnt += 1
            valid_addresses << email_addr  
          end
        else
          err_addresses << email_addr
        end
        
      end
    }
    
    
    return [addr_cnt, validated_addr_cnt, valid_addresses, db_user_addresses, err_addresses]
  end
  
  
  
  # sends an email for each of the email addresses in the collection;
  # params : 1) 'type' - "invite"s to myExperiment; "group_invite"s, etc.
  #          2) 'base_host' - base url of the website
  #          3) 'user' - user_id that is sending the messages
  #          4) 'email_list' - array of destination email addresses
  #          5) 'msg_text' - personal message to include with each email apart from default text
  #          6) 'id_of_group_to_join' - id of the group for which membership invite is sent;
  #                                     should be 'nil' (and will be ignored) for any non-membership invitations
  def self.send_invitation_emails (type, base_host, user, email_list, msg_text, id_of_group_to_join = nil)
    email_list.each { |email_addr, token|
      # decide which action to make
      case type
        when "invite"
          Mailer.deliver_invite_new_user(user, email_addr, msg_text)
        when "group_invite"
          group = Network.find(id_of_group_to_join)
          Mailer.deliver_group_invite_new_user(user, group, email_addr, msg_text, token)
        when "friendship_invite"
          Mailer.deliver_friendship_invite_new_user(user, email_addr, msg_text, token)
      end
    }    
  end
  
end
