module ActsAsTaggableHelper
  # Create a link to the tag using restful routes and the rel-tag microformat
  def link_to_tag(tag)
    link_to(h(tag.name), tag_path(tag), :rel => 'tag')
  end
  
  # Generate a tag cloud of the top 100 tags by usage, uses the proposed hTagcloud microformat.
  #
  # Inspired by http://www.juixe.com/techknow/index.php/2006/07/15/acts-as-taggable-tag-cloud/
  # Hacked to shreds by Mark Borkum (mib104@ecs.soton.ac.uk)
  def tag_cloud(limit=100, options = {})
    l_option = limit ? { :limit => limit } : { }
    
    # TODO: add options to specify different limits and sorts
    tags = Tag.find(:all, l_option.merge({ :order => 'taggings_count DESC'})).sort_by(&:name)
    
    return tag_cloud_from_collection(tags, true)
  end
    
  def tag_cloud_from_collection(tags, original=false, link_to_type=nil)
    tags = tags.sort { |a, b|
      a.name.downcase <=> b.name.downcase
    }
    
    # tags array might contain duplicates (however this is ok, because
    # it is planned to display the tag cloud in a way that most frequent
    # tags for current contributable are of larger size with no
    # respect to how frequent they are on the website in general);
    #
    # for now, we just filter out duplicates, so that each tag is display
    # only once in the tag cloud
    tags = tags.uniq
    
    
    # TODO: add option to specify which classes you want and overide this if you want?
    classes = %w(popular v-popular vv-popular vvv-popular vvvv-popular)
    
    max, min = 0, 0
    tags.each do |tag|
      max = tag.taggings_count if tag.taggings_count > max
      min = tag.taggings_count if tag.taggings_count < min
    end
    
    divisor = ((max - min) / classes.size) + 1
    
    count = 0;
    
    html =    %(<div class="hTagcloud">\n)
    html <<   %(  <ul class="popularity">\n)
    tags.each do |tag|
      html << %(    <li>)
      
      if original
        unless link_to_type.blank?
          html << link_to(h(tag.name), tag_path(tag) + "?type=#{link_to_type}", :class => classes[(tag.taggings_count - min) / divisor])
        else
          html << link_to(h(tag.name), tag_path(tag), :class => classes[(tag.taggings_count - min) / divisor])
        end
      else
        unless link_to_type.blank?
          html << "<a href='#{tag_path(Tag.find(:first, :conditions => ["name = ?", tag.name]))}?type=#{link_to_type}' class='#{classes[(tag.taggings_count - min) / divisor]}'>#{h(tag.name)}</a>"
        else
          html << "<a href='#{tag_path(Tag.find(:first, :conditions => ["name = ?", tag.name]))}' class='#{classes[(tag.taggings_count - min) / divisor]}'>#{h(tag.name)}</a>"
        end
      end
      
      html << %(</li>\n)
      
      count += 1;
      
      if count < tags.length
        html << %(<li> | </li>\n)
      end
    end
    html <<   %(  </ul>\n)
    html <<   %(</div>\n)
  end
end
