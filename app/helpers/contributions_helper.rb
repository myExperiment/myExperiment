# myExperiment: app/helpers/contributions_helper.rb
#
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

module ContributionsHelper

  def describe_version(version_number, version_count)
    return "" if version_count < 2
    return "(of #{version_count})"
  end

end
