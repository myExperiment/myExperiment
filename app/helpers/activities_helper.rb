# myExperiment: app/helpers/activities_helper.rb
#
# Copyright (c) 2007-2013 The University of Manchester, the University of
# Oxford, and the University of Southampton.  See license.txt for details.

module ActivitiesHelper

  def activity_link(activity, source)

    case source
    when :subject
      thing = activity.subject
      label = activity.subject_label
    when :object
      thing = activity.objekt
      label = activity.objekt_label
    when :context
      thing = activity.context
      label = activity.context.label
    when :auth
      thing = activity.auth
      label = activity.auth.label
    end

    thing = thing.versioned_resource if thing.respond_to?(:versioned_resource)

    if thing
      path = case thing.class.name
        when "Bookmark"
          polymorphic_path(thing.bookmarkable)
        when "Comment"
          polymorphic_path(thing.commentable)
        when "Citation"
          polymorphic_path(thing.workflow)
        when "GroupAnnouncement"
          group_announcement_path(thing.network, thing)
        else
          polymorphic_path(thing)
      end

      link_to(h(label), path)
    else
      h(label)
    end
  end
  
  def combine_activities?(a, b)

    return false if a.action != b.action
    return false if a.objekt_type != b.objekt_type

    return true if a.action == 'create' && a.objekt_type == 'Membership'
    return true if a.action == 'create' && a.objekt_type == 'Tagging' && a.subject == b.subject

    false
  end

  def activities_for_feed(opts)

    page     = opts.delete(:page)     || 1
    per_page = opts.delete(:per_page) || 12

    first    = (page - 1) * per_page
    last     = first + (per_page - 1)

    # Create the conditions based on the contexts (resources to which news
    # items belong) and also the types of new items to show.

    context_bits = []
    context_vars = []

    if opts[:context]
      context_bits << "(activities.context_type = ? AND activities.context_id = ?)"
      context_vars << opts[:context].class.name
      context_vars << opts[:context].id
    else
      
    end

    type_bits = []
    type_vars = []

    type_bits << "(activities.objekt_type = 'Network' AND activities.action = 'create')"
    type_bits << "(activities.objekt_type = 'FeedItem' AND activities.action = 'create')"
    type_bits << "(activities.objekt_type = 'Permission' AND activities.action = 'create')"
    type_bits << "(activities.objekt_type = 'Comment' AND activities.action = 'create')"
    type_bits << "(activities.objekt_type = 'GroupAnnouncement' AND activities.action = 'create')"
    type_bits << "(activities.objekt_type = 'Membership' AND activities.action = 'create')"

    # Create the conditions

    if (context_bits.empty? && type_bits.empty?)
      conditions = nil
    elsif (!context_bits.empty? && type_bits.empty?)
      conditions = ["(" + context_bits.join(" OR ") + ")", *context_vars]
    elsif (context_bits.empty? && !type_bits.empty?)
      conditions = ["(" + type_bits.join(" OR ") + ")", *type_vars]
    else
      conditions = ["((" + context_bits.join(" OR ") + ") AND (" + type_bits.join(" OR ") + "))", *(context_vars + type_vars)]
    end

    order = 'featured DESC, timestamp DESC, priority ASC'

    activities = Authorization.scoped(Activity,
        :auth_type       => 'activities.auth_type',
        :auth_id         => 'activities.auth_id',
        :group           => 'activities.id',
        :authorised_user => opts[:user])
    
    results = []
    pos = 0

    while results.length <= last
      incoming = activities.all(:conditions => conditions, :order => order, :limit => "#{pos}, #{per_page}")
      
      break if incoming.length == 0

      incoming.each do |activity|

        # Special case for group announcements as they can be made private.

        if activity.objekt.kind_of?(GroupAnnouncement) && !activity.objekt.public
          next unless logged_in?
          next unless activity.objekt.network.member?(current_user)
        end

        if results.length > 0 && !opts[:no_combine] && combine_activities?(activity, results.last.first)
          results.last << activity
        else
          results << [activity]
        end
      end

      pos = pos + per_page
    end
    
    results[first..last]
  end

  def sentence(bits)
    result = ""

    bits.each_index do |i|
      result << bits[i]
      result << ", " unless i == bits.length - 1
      result << "and " if i == bits.length - 2
    end

    result
  end

  def activity_text_summary(text, opts = {})

    tokens = HTML::Tokenizer.new(CGI::unescapeHTML(text))

    result = ""

    while (token = tokens.next) do
      node = HTML::Node.parse(nil, 0, 0, token, false)
      result << node.to_s if node.kind_of?(HTML::Text) || node.kind_of?(String)
      result << " "
    end

    result = result.gsub(/\s+/, ' ').strip

    min_chars = opts[:min_chars] || 200

    if (result.length > min_chars)
      result = h("#{result[0..min_chars]}") + " &#8230;"
    end

    "<div class='summary'>#{result}</div>"
  end

  def news_item_avatar(news_items)

    news_item = news_items.first

    # Only show an image if all the subjects match

    if news_items.length > 1
      news_items.each do |news_item|
        return if news_item.subject != news_item.subject
      end
    end
  
    if news_item.subject_type == 'User'
      avatar(news_item.subject_id, 48)
    elsif news_item.subject_type == 'Network'
      avatar(news_item.subject.owner.id, 48)
    end
  end

  def activity_title(activity_set)

    activity = activity_set.first

    case activity.objekt ? "#{activity.objekt_type} #{activity.action}" : activity.action
    when "Announcement create"
      "#{activity_link(activity, :subject)} announced #{activity_link(activity, :object)}"
    when "Announcement edit"
      "#{activity_link(activity, :subject)} edited #{activity_link(activity, :object)}"
    when "Blob create"
      "#{activity_link(activity, :subject)} uploaded #{activity_link(activity, :object)}"
    when "Blob edit"
      "#{activity_link(activity, :subject)} edited #{activity_link(activity, :object)}"
    when "BlobVersion create"
      "#{activity_link(activity, :subject)} uploaded version #{activity.extra} of #{activity_link(activity, :object)}"
    when "BlobVersion edit"
      "#{activity_link(activity, :subject)} edited version #{activity.extra} of #{activity_link(activity, :object)}"
    when "Bookmark create"
      "#{activity_link(activity, :subject)} favourited #{activity_link(activity, :object)}"
    when "Citation create"
      "#{activity_link(activity, :subject)} added the citation #{activity_link(activity, :object)} to #{activity_link(activity, :auth)}"
    when "Citation edit"
      "#{activity_link(activity, :subject)} edited the citation #{activity_link(activity, :object)} on #{activity_link(activity, :auth)}"
    when "Comment create"
      "#{activity_link(activity, :subject)} commented:"
    when "Friendship create"
      user1 = activity.subject = activity.context ? activity.objekt.user : activity.objekt.friend
      user2 = activity.subject = activity.context ? activity.objekt.friend : activity.objekt.user
      "#{link_to(h(user1.name), polymorphic_path(user1))} is friends with #{link_to(h(user2.name), polymorphic_path(user2))}"
    when "Network create"
      "#{activity_link(activity, :subject)} created the #{activity_link(activity, :object)} group"
    when "Network edit"
      "#{activity_link(activity, :subject)} edited the #{activity_link(activity, :object)} group"
    when "Pack create"
      "#{activity_link(activity, :subject)} created #{activity_link(activity, :object)}"
    when "Pack edit"
      "#{activity_link(activity, :subject)} edited #{activity_link(activity, :object)}"
    when "Rating create"
      "#{activity_link(activity, :subject)} rated #{activity_link(activity, :auth)} with #{activity.extra}"
    when "Review create"
      "#{activity_link(activity, :subject)} reviewed #{activity_link(activity, :auth)}"
    when "Review edit"
      "#{activity_link(activity, :subject)} edited a review on #{activity_link(activity, :auth)}"
    when "Tagging create"
      "#{activity_link(activity, :subject)} tagged #{activity_link(activity, :auth)} with #{sentence(activity_set.map { |a| link_to(h(a.objekt.tag.name), tag_path(a.objekt.tag)) })}"
    when "Workflow create"
      "#{activity_link(activity, :subject)} uploaded #{activity_link(activity, :object)}"
    when "Workflow edit"
      "#{activity_link(activity, :subject)} edited #{activity_link(activity, :object)}"
    when "WorkflowVersion create"
      "#{activity_link(activity, :subject)} uploaded version #{activity.extra} of #{activity_link(activity, :object)}"
    when "WorkflowVersion edit"
      "#{activity_link(activity, :subject)} edited version #{activity.extra} of #{activity_link(activity, :object)}"
    when "edit"
      "#{activity_link(activity, :subject)} edited their profile"
    when "register"
      "#{activity_link(activity, :subject)} joined #{Conf.sitename}"
    when "Membership create"
      "#{sentence(activity_set.map { |a| activity_link(a, :subject) })} joined the #{activity_link(activity, :context)} group"
    when "Permission create"
      "#{activity_link(activity, :subject)} shared #{activity_link(activity, :auth)}"
    when "FeedItem create"
      link_to(h(activity.objekt.title), activity.objekt.link, :rel => "nofollow")
    when "GroupAnnouncement create"
      activity_link(activity, :object)
    end
  end

  def activity_description(activity_set, opts = {})

    min_chars = opts[:min_chars] || 300

    activity = activity_set.first

    case activity.objekt ? "#{activity.objekt_type} #{activity.action}" : activity.action
    when "BlobVersion create"
      activity.objekt.body_html
    when "Comment create"
      "<a name='comment_#{activity.objekt.id}'></a>#{activity_text_summary(activity.objekt.comment, :min_chars => min_chars)}"
    when "Workflow create"
      "<div style='float: left; width: 64px'>#{link_to(image_tag(workflow_version_preview_path(activity.objekt, 1, 'thumb'), :width => 64, :height => 64), workflow_version_path(activity.objekt 1))}</div><div class='activity-text'>#{activity.objekt.body_html}</div>"
    when "WorkflowVersion create"
      "<div style='float: left; width: 64px'>#{link_to(image_tag(workflow_version_preview_path(activity.objekt.workflow, activity.objekt.version, 'thumb'), :width => 64, :height => 64), workflow_version_path(activity.objekt.workflow, activity.objekt.version))}</div><div class='activity-text'>#{white_list(activity.objekt.revision_comments)}</div>"
    when "Permission create"
      case activity.auth
      when Workflow
        "<div><div style='float: left; margin: 6px'>#{link_to(image_tag(workflow_preview_path(activity.auth, 'thumb'), :width => 64, :height => 64), workflow_path(activity.auth))}</div>#{activity_text_summary(activity.auth.body_html, :min_chars => min_chars)}<div style='clear: both'></div></div>"
      when Blob, Pack
        "<div>#{activity_text_summary(activity.auth.body_html, :min_chars => min_chars)}</div>"
      end
    when "FeedItem create"
      "<div class='summary'>#{activity_text_summary(activity.objekt.content, :min_chars => min_chars)}</div>"
    when "GroupAnnouncement create"
      activity_text_summary(activity.objekt.body_html, :min_chars => min_chars)
    end
  end

  def activity_extra(activity_set, opts = {})

    activity = activity_set.first

    case activity.objekt ? "#{activity.objekt_type} #{activity.action}" : activity.action
    when "FeedItem create"
      "<div class='extra'>#{image_tag("feed_gray.png", :size => "10x10", :alt_text => "Original atom feed for this news item")} Content via #{link_to(h(activity.objekt.feed.uri), activity.objekt.feed.uri)}</div>"
    end
  end
end

