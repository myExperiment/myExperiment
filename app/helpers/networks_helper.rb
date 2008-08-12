# myExperiment: app/helpers/networks_helper.rb
#
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

module NetworksHelper
  
  # chooses, which of the DIVs will be selected on the invite page, based
  # on the value of a paramater
  def invite_existing_selected?(radio_choice)
    if radio_choice.nil?
      return( true )
    else
      return( radio_choice == "existing" ? true : false )  
    end
  end
  
end
