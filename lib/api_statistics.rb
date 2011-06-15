# myExperiment: lib/api_statistics.rb
#
# Copyright (c) 2011 University of Manchester and the University of Southampton.
# See license.txt for details.

module APIStatistics

  def self.statistics(ob)

    total_viewings  = Viewing.count(:conditions => ['contribution_id = ?', ob.contribution.id])
    site_viewings   = Viewing.count(:conditions => ['contribution_id = ? AND accessed_from_site = 1', ob.contribution.id])
    other_viewings  = Viewing.count(:conditions => ['contribution_id = ? AND accessed_from_site = 0', ob.contribution.id])

    total_downloads = Download.count(:conditions => ['contribution_id = ?', ob.contribution.id])
    site_downloads  = Download.count(:conditions => ['contribution_id = ? AND accessed_from_site = 1', ob.contribution.id])
    other_downloads = Download.count(:conditions => ['contribution_id = ? AND accessed_from_site = 0', ob.contribution.id])

    result = XML::Node.new('statistics')

    viewings_element = XML::Node.new('viewings')
    
    viewings_element << (XML::Node.new('total') << total_viewings)

    viewings_breakdown_element = XML::Node.new('breakdown')

    viewings_breakdown_element << (XML::Node.new('site')  << site_viewings)
    viewings_breakdown_element << (XML::Node.new('other') << other_viewings)

    viewings_element << viewings_breakdown_element

    downloads_element = XML::Node.new('downloads')

    downloads_element << (XML::Node.new('total') << total_downloads)

    downloads_breakdown_element = XML::Node.new('breakdown')

    downloads_breakdown_element << (XML::Node.new('site')  << site_downloads)
    downloads_breakdown_element << (XML::Node.new('other') << other_downloads)

    downloads_element << downloads_breakdown_element

    result << viewings_element
    result << downloads_element

    result
  end

end

