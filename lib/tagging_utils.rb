module TaggingUtils

  def replace_tags(object, tagger, tag_list)
    ActsAsTaggableOn::Tagging.transaction do
      old_taggings = ActsAsTaggableOn::Tagging.where(:taggable_type => object.class, :taggable_id => object,
                                                     :tagger_type => tagger.class, :tagger_id => tagger)
      old_taggings.destroy_all

      tagger.tag(object, :with => tag_list, :on => :tags)
    end
  end

end
