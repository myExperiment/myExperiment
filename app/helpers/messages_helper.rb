# myExperiment: app/helpers/messages_helper.rb
#
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

module MessagesHelper
  def reply_message_path(message)
    url_for :action => "new", :reply_id => message
  end
  
  
  # returns a value for default ordering by this field:
  def default_ordering(field_name)
    case field_name
      when "status";  return("ascending")
      when "from";    return("ascending")
      when "subject"; return("ascending")
      when "date";    return("descending")
    end  
  end
  
  
  def opposite_ordering( ordering )
    if( ordering == "ascending" );    return "descending"
    elsif( ordering =="descending");  return "ascending"
    else                              return "ascending"  # default value, but still worth putting aside, as might change
    end
  end
  
  
  # determines whether current sorting was done by this field or not
  def ordered_by(field_name)
    
    # if no field is set for sorting, request to sort by date is assumed
    if params[:sort_by].blank?
      return( field_name == "date" )
    else
      return( field_name == params[:sort_by] )
    end
    
  end
  
  
  # determines what should be the ordering after a reload for a field in the link -- 
  # if was sorted by that field now, use ordering which is opposite from current one;
  # use default ordering for that field otherwise
  def next_ordering(field_name)
     
     if( ordered_by(field_name) )
       if params[:sort_by].blank?
         # unusual case - sorted by 'date' by default; not set in 'params'
         return( opposite_ordering(default_ordering("date")) )
       else
         return( opposite_ordering(params[:order]) )
       end
     else
       return( default_ordering(field_name) )
     end
     
  end
 
  
  # produces a code to display an arrow icon next to the 
  # header in the table - the arrow showing the direction of
  # ordering on that field, if it was used for current ordering
  def current_ordering_icon(field_name)
    
    if( ! ordered_by(field_name) )
      return ''
    else
      if( opposite_ordering(next_ordering(field_name)) == "ascending" )
        return( icon('arrow_up', nil, nil, nil, '') )
      else
        return( icon('arrow_down', nil, nil, nil, '') )
      end
    end

  end

  
  # returns a message to display in the tooltip for table header column,
  # if ordered by this column at the moment
  def tooltip_message(field_name, order)
    msg = ""
    
    if( ordered_by(field_name) )
      msg += "<p><b>Currently sorted by #{field_name}, #{sorting_message(field_name,order)}.</b></p>"
    end
  
    msg += "<p>Click here to sort by #{field_name}, #{sorting_message(field_name,opposite_ordering(order))}.</p>"
  
    return( msg )
  end
  
  
  # a helper method for 'tooltip_message()'
  def sorting_message(field_name, order)
    case field_name
      when "status"
        if( order == "ascending" )
          return "unread messages at the top"
        else
          return "most recently read messages at the top"
        end
      when "subject"
        if( order == "ascending" )
          return "alphabetically in ascending order"
        else
          return "alphabetically in descending order"
        end
      when "date"
        if( order == "ascending" )
          return "oldest messages first"
        else
          return "most recent messages first"
        end
    end
  end
  
end
