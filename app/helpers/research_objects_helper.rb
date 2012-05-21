# myExperiment: app/helpers/research_objects_helper.rb
#
# Copyright (c) 2012 University of Manchester and the University of Southampton.
# See license.txt for details.

module ResearchObjectsHelper

  def research_object_summary(ro)

    s_uris = []
    p_uris = []
    o_uris = []

    ro.annotations.each do |annotation|
      s_uris << annotation.subject_text
      p_uris << annotation.predicate_text
      o_uris << annotation.objekt_text
    end

    uris = (s_uris + p_uris + o_uris).uniq!
    
    uris.map! do |uri|
      [uri, s_uris.select do |u| u == uri end.length,
            p_uris.select do |u| u == uri end.length,
            o_uris.select do |u| u == uri end.length]
    end

    uris.sort! do |a, b|
      by_count = (b[1] + b[2] + b[3]) <=> (a[1] + a[2] + a[3])

      if by_count == 0
        b[0] <=> a[0]
      else
        by_count
      end
    end

    uris
  end

end
