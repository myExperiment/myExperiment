# myExperiment: app/models/feeds.rb
#
# Copyright (c) 2007-2013 The University of Manchester, the University of
# Oxford, and the University of Southampton.  See license.txt for details.

require 'simple-rss'
require 'open-uri'
require 'curb'

class Feed < ActiveRecord::Base

  attr_accessible :uri, :username, :password

  attr_encrypted :password, :key => Conf.sym_encryption_key, :algorithm => 'des-ede3-cbc'

  belongs_to :context, :polymorphic => true

  has_many :feed_items, :dependent => :destroy

  def synchronize!

    if uri

       begin

        c = Curl::Easy.new(uri)
        c.http_auth_types = :basic

        if username && password
          c.username = username
          c.password = password.decrypt
        end

        c.perform

        result = SimpleRSS.parse(c.body_str)

        title = result.send(:title)

        update_attribute(:title, title) if title

        result.feed.items.each do |item|

          # Obtain a unique identifier for use within the context of this feed.
          identifier = item[:id]

          # Try to find an existing item in this feed using the identifier.
          object = feed_items.find_by_identifier(item[:id])

          if object.nil?
            # Create a new object if an existing object wasn't found.
            object = feed_items.new if object.nil?

            notify = true
          end

          object.identifier        = item[:id]
          object.title             = item[:title]
          object.content           = item[:content]
          object.author            = item[:author]
          object.link              = item[:link]
          object.item_published_at = item[:published]

          success = object.save

          if (success && notify)
            Activity.create_activities(:subject => context, :action => 'create', :object => object, :timestamp => object.item_published_at)
          end
        end

      rescue
        return false
      end
    end
  end
end

