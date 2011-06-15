# myExperiment: app/controllers/linked_data_controller.rb
#
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

class LinkedDataController < ApplicationController

  before_filter :check_contributable_for_view_permission, :only => [ :attributions, :citations, :comments, :credits, :local_pack_entries, :remote_pack_entries, :policies, :ratings ]

  def attributions

    attribution = Attribution.find_by_id(params[:attribution_id])

    return not_found if attribution.nil?
    return not_found if attribution.attributable != @contributable

    respond_to do |format|
      if Conf.rdfgen_enable
        format.rdf {
          render :inline => `#{Conf.rdfgen_tool} attributions #{attribution.id}`
        }
      end
    end
  end

  def citations

    citation = Citation.find_by_id(params[:citation_id])

    return not_found if citation.nil?
    return not_found if citation.workflow != @contributable

    respond_to do |format|
      if Conf.rdfgen_enable
        format.rdf {
          render :inline => `#{Conf.rdfgen_tool} citations #{citation.id}`
        }
      end
    end
  end

  def comments

    comment = Comment.find_by_id(params[:comment_id])

    return not_found if comment.nil?
    return not_found if comment.commentable != @contributable

    respond_to do |format|
      if Conf.rdfgen_enable
        format.rdf {
          render :inline => `#{Conf.rdfgen_tool} comments #{comment.id}`
        }
      end
    end
  end

  def credits

    credit = Creditation.find_by_id(params[:credit_id])

    return not_found if credit.nil?
    return not_found if credit.creditable != @contributable

    respond_to do |format|
      if Conf.rdfgen_enable
        format.rdf {
          render :inline => `#{Conf.rdfgen_tool} creditations #{credit.id}`
        }
      end
    end
  end

  def favourites

    user      = User.find_by_id(params[:user_id])
    favourite = Bookmark.find_by_id(params[:favourite_id])

    return not_found if user.nil?
    return not_found if favourite.nil?
    return not_found if favourite.user != user

    respond_to do |format|
      if Conf.rdfgen_enable
        format.rdf {
          render :inline => `#{Conf.rdfgen_tool} favourites #{favourite.id}`
        }
      end
    end
  end

  def local_pack_entries

    local_pack_entry = PackContributableEntry.find_by_id(params[:local_pack_entry_id])

    return not_found if local_pack_entry.nil?
    return not_found if local_pack_entry.pack != @contributable

    respond_to do |format|
      if Conf.rdfgen_enable
        format.rdf {
          render :inline => `#{Conf.rdfgen_tool} local_pack_entries #{local_pack_entry.id}`
        }
      end
    end
  end

  def remote_pack_entries

    remote_pack_entry = PackRemoteEntry.find_by_id(params[:remote_pack_entry_id])

    return not_found if remote_pack_entry.nil?
    return not_found if remote_pack_entry.pack != @contributable

    respond_to do |format|
      if Conf.rdfgen_enable
        format.rdf {
          render :inline => `#{Conf.rdfgen_tool} remote_pack_entries #{remote_pack_entry.id}`
        }
      end
    end
  end

  def policies

    policy = Policy.find_by_id(params[:policy_id])

    return not_found if policy.nil?
    return not_found if policy.contributions.include?(@contributable.contribution) == false

    respond_to do |format|
      if Conf.rdfgen_enable
        format.rdf {
          render :inline => `#{Conf.rdfgen_tool} policies #{policy.id}`
        }
      end
    end
  end

  def ratings

    rating = Rating.find_by_id(params[:rating_id])

    return not_found if rating.nil?
    return not_found if rating.rateable != @contributable

    respond_to do |format|
      if Conf.rdfgen_enable
        format.rdf {
          render :inline => `#{Conf.rdfgen_tool} ratings #{rating.id}`
        }
      end
    end
  end

  def taggings

    tag     = Tag.find_by_id(params[:tag_id])
    tagging = Tagging.find_by_id(params[:tagging_id])

    return not_found if tag.nil?
    return not_found if tagging.nil?
    return not_found if tagging.tag != tag
    return not_auth  if Authorization.is_authorized?('view', nil, tagging.taggable, current_user) == false

    respond_to do |format|
      if Conf.rdfgen_enable
        format.rdf {
          render :inline => `#{Conf.rdfgen_tool} taggings #{tagging.id}`
        }
      end
    end
  end

  private

  def check_contributable_for_view_permission

    @contributable = case params[:contributable_type]
      when 'workflows'; Workflow.find_by_id(params[:contributable_id])
      when 'files';     Blob.find_by_id(params[:contributable_id])
      when 'packs';     Pack.find_by_id(params[:contributable_id])
    end

    return not_found if @contributable.nil?
    return not_auth  if Authorization.is_authorized?('view', nil, @contributable, current_user) == false
  end

  def not_found
    render(:inline => 'Not Found', :status => "404 Not Found")
    false
  end

  def not_auth
    response.headers['WWW-Authenticate'] = "Basic realm=\"#{Conf.sitename}\""
    render(:inline => 'Not Found', :status => "401 Unauthorized")
    false
  end
end

