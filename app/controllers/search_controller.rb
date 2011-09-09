# myExperiment: app/controllers/search_controller.rb
#
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

class SearchController < ApplicationController

  include ApplicationHelper

  def show

    if params[:query].nil? or params[:query] == ''
      flash[:error] = 'Missing search query';
      redirect_to url_for(:controller => "home")
      return
    end

    @type = params[:type].to_s.downcase
    
    @type = "all" if @type.nil? or @type == ""

    if !Conf.search_categories.include?(@type)
      error(@type)
      return false
    end

    if Conf.model_aliases.key?(@type.camelize.singularize)
      @type = Conf.model_aliases[@type.camelize.singularize].pluralize.underscore
    end

    if @type == "all"
      search_all
    else
      case params[:type]
      when 'workflows'
        redirect_to(workflows_path(:query => params[:query]))
      when 'files'
        redirect_to(files_path(:query => params[:query]))
      when 'packs'
        redirect_to(packs_path(:query => params[:query]))
      when 'services'
        redirect_to(services_path(:query => params[:query]))
      else
        search_model
      end
    end
  end
  
  def open_search_beta

    def time_string(time)
      time.strftime("%a, %d %b %Y %I:%H:%S %Z")
    end

    def file_column_url(ob, field)

      fields = (field.split('/').map do |f| "'#{f}'" end).join(', ')

      path = eval("ActionView::Base.new.url_for_file_column(ob, #{fields})")

      "#{request.protocol}#{request.host_with_port}#{path}"
    end

    def render_user(u)

      markup = ""

      markup += "<item>";
      markup += "<title>" + u.name + "</title>";
      markup += "<link>" + user_url(u) + "</link>";
      markup += "<description>" + sanitize(u.profile.body_html) + "</description>";
      markup += "<pubDate>" + time_string(u.created_at) + "</pubDate>";

      if u.profile.picture
        markup += "<media:thumbnail url=\"" + user_picture_url(u, u.profile.picture.id) + "\"/>";
      else
        markup += "<media:thumbnail url=\"" + Conf.base_uri + "/images/avatar.png\"/>";
      end

      markup += "</item>";

      markup
    end

    def sanitize(str)
      str = str.gsub('<[^>]*>', '')
      str = str.gsub('&', '')
      str
    end

    def render_workflow(w)

      markup = ""

      markup += "<item>";
      markup += "<title>" + w.title + "</title>";
      markup += "<link>" + workflow_url(w) + "</link>";
      markup += "<description>" + sanitize(w.body_html) + "</description>";
      markup += "<pubDate>" + time_string(w.created_at) + "</pubDate>";
      markup += "<media:content url=\"" + w.named_download_url + "\"";
      markup += " fileSize=\"" + w.content_blob.data.length.to_s + "\"" +
                " type=\"" + w.content_type.mime_type + "\"/>";
      markup += "<media:thumbnail url=\"" + file_column_url(w, "image/thumb") +
          "\"/>";
#markup += "height=\"120\" width=\"160\"/>";

      w.tags.each do |t|
        markup += "<category>#{t.name}</category>"
      end

      markup += "<author>#{w.contributor.name}</author>"

      markup += "</item>";

      markup
    end

    def render_file(f)

      markup = ""

      markup += "<item>";
      markup += "<title>" + f.title + "</title>";
      markup += "<link>" + file_url(f) + "</link>";
      markup += "<description>" + sanitize(f.body_html) + "</description>";
      markup += "<pubDate>" + time_string(f.created_at) + "</pubDate>";
      markup += "<media:content url=\"" + f.named_download_url + "\"";
      markup += " fileSize=\"" + f.content_blob.data.length.to_s + "\"" +
                " type=\"" + f.content_type.mime_type + "\"/>";

      f.tags.each do |t|
        markup += "<category>#{t.name}</category>"
      end

      markup += "<author>#{f.contributor.name}</author>"

      markup += "</item>";

      markup
    end

    markup = ""

    markup += "<rss version=\"2.0\" xmlns:media=\"http://search.yahoo.com/mrss/\" "
    markup += "xmlns:example=\"http://example.com/namespace\">"
    markup += "<channel>";
    markup += "<title>Search Results</title>";

    if (params["q"] != "*")
      begin
        query = params["q"].downcase

        results = User.multi_solr_search(query, :models => [Workflow, Blob, User], :limit => 25).results

        results.each do |result|
          case result.class.name
            when "Workflow"; markup += render_workflow(result)
            when "Blob";     markup += render_file(result)
            when "User";     markup += render_user(result)
          end
        end
      rescue
        # most likely here because of an invalid search query
      end
    end

    markup += "</channel>";
    markup += "</rss>";

    response.content_type = "application/rss+xml"

    render :text => markup
  end

private

  def error(type)
    flash[:error] = "'#{type}' is an invalid search type"
    
    respond_to do |format|
      format.html { redirect_to url_for(:controller => "home") }
    end
  end

  def search_all

    @query = params[:query]

    @pivot_options = pivot_options

    begin
      expr = parse_filter_expression(params["filter"]) if params["filter"]
    rescue Exception => ex
      puts "ex = #{ex.inspect}"
      flash.now[:error] = "Problem with query expression: #{ex}"
      expr = nil
    end

    @pivot = contributions_list(Contribution, params, current_user,
        :filters => expr, :arbitrary_models => true)

  end

  def search_model

    model_name = params[:type].singularize.camelize
    model_name = Conf.model_aliases[model_name] if Conf.model_aliases[model_name]

    model = eval(model_name)

    @collection_label = params[:type].singularize
    @controller_name  = model_name.underscore.pluralize
    @visible_name     = params[:type].capitalize
    @query_type       = params[:type]

    @query = params[:query] || ''
    @query.strip!

    limit = params[:num] ? params[:num] : Conf.default_search_size

    limit = 1                    if limit < 1
    limit = Conf.max_search_size if limit > Conf.max_search_size

    offset = params[:page] ? limit * (params[:page].to_i - 1) : 0

    if Conf.solr_enable && !@query.blank?
      begin
        solr_results = model.find_by_solr(@query.downcase, :offset => offset, :limit => limit)
        @total_count = solr_results.total
        @collection  = PaginatedArray.new(solr_results.results,
            :offset => offset, :limit => limit, :total => @total_count)
      rescue
        flash.now[:error] = "There was a problem with your search query."
        @total_count = 0
        @collection  = PaginatedArray.new([], :offset => offset, :limit => limit, :total => 0)
      end
    else
      @total_count = 0
      @collection  = PaginatedArray.new([], :offset => offset, :limit => limit, :total => 0)
    end

    render("search/model")
  end
end
