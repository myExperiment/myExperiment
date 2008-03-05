class QuestionsController < ApplicationController  
  before_filter :login_required, :except => [:index, :show, :search, :all]
  
  before_filter :find_questions, :only => [:index, :all]
  #before_filter :find_questions_auth, :only => [:bookmark, :comment, :rate, :tag, :download, :show, :edit, :update, :destroy]
  before_filter :find_question_auth, :except => [:search, :index, :new, :create, :all]
  
  # GET /questions;search
  # GET /questions.xml;search
  def search

    @query = params[:query] == nil ? "" : params[:query]
    
    @questions = SOLR_ENABLE ? Question.find_by_solr(@query, :limit => 100).results : []
    
    respond_to do |format|
      format.html # search.rhtml
      format.xml  { render :xml => @questions.to_xml }
    end
  end
  
  # GET /questions
  # GET /questions.xml
  def index
    respond_to do |format|
      format.html # index.rhtml
      format.xml  { render :xml => @questions.to_xml }
    end
  end
  
   # GET /questions/all
  def all
    respond_to do |format|
      format.html # all.rhtml
    end
  end

  # GET /questions/1
  # GET /questions/1.xml
  def show
    @viewing = Viewing.create(:contribution => @question.contribution, :user => (logged_in? ? current_user : nil))
    
    @sharing_mode  = determine_sharing_mode(@question)
    
    respond_to do |format|
      format.html # show.rhtml
      format.xml  { render :xml => @question.to_xml }
    end
  end

  # GET /questions/new
  def new
    @question = Question.new

    @sharing_mode  = 0
  end

  # GET /questions/1;edit
  def edit
    @sharing_mode  = determine_sharing_mode(@question)
  end
 
  # POST /questions
  # POST /questions.xml
  def create

    params[:question][:contributor_type], params[:question][:contributor_id] = "User", current_user.id
    
    # create workflow using helper methods
    @question = create_question(params[:question])
    
    respond_to do |format|
      if @question.save
        if params[:question][:tag_list]
          @question.tags_user_id = current_user
          @question.tag_list = convert_tags_to_gem_format params[:question][:tag_list]
          @question.update_tags
        end
                
        @question.contribution.update_attributes(params[:contribution])

        update_policy(@question, params)
        
        # Credits and Attributions:
        update_credits(@question, params)
        update_attributions(@question, params)

        flash[:notice] = 'Question was successfully created.'
        format.html { redirect_to question_url(@question) }
        format.xml  { head :created, :location => question_url(@question) }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @question.errors.to_xml }
      end
    end
  end
 
 
  
  # PUT /questions/1
  # PUT /questions/1.xml
  def update
    
    # remove protected columns
    if params[:question]
      [:contributor_id, :contributor_type, :created_at].each do |column_name|
        params[:question].delete(column_name)
      end
    end
    
    respond_to do |format|
      if @question.update_attributes(params[:question])
        
        refresh_tags(@question, params[:question][:tag_list], current_user) if params[:question][:tag_list]
        update_policy(@question, params)
        update_credits(@question, params)
        update_attributions(@question, params)

        flash[:notice] = 'Question was successfully updated.'
        format.html { redirect_to question_url(@question) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @question.errors.to_xml }
      end
    end
  end

  # DELETE /questions/1
  # DELETE /questions/1.xml
  def destroy
    @question.destroy

    respond_to do |format|
      format.html { redirect_to questions_url }
      format.xml  { head :ok }
    end
  end
  
  
  # POST /questions/1;bookmark
  # POST /questions/1.xml;bookmark
  def bookmark
    @question.bookmarks << Bookmark.create(:user => current_user, :title => @question.title) unless @question.bookmarked_by_user?(current_user)
    
    respond_to do |format|
      format.html { render :inline => "<%=h @question.bookmarks.collect {|b| b.user.name}.join(', ') %>" }
      format.xml { render :xml => @question.bookmarks.to_xml }
    end
  end
  
  # POST /questions/1;comment
  # POST /questions/1.xml;comment
  def comment
    text = params[:comment][:comment]
    
    if text and text.length > 0
      comment = Comment.create(:user => current_user, :comment => text)
      @question.comments << comment
    end
  
    respond_to do |format|
      format.html { render :partial => "comments/comments", :locals => { :commentable => @question } }
      format.xml { render :xml => @question.comments.to_xml }
    end
  end
  
  # DELETE /questions/1;comment_delete
  # DELETE /questions/1.xml;comment_delete
  def comment_delete
    if params[:comment_id]
      comment = Comment.find(params[:comment_id].to_i)
      # security checks:
      if comment.user_id == current_user.id and comment.commentable_type.downcase == 'question' and comment.commentable_id == @question.id
        comment.destroy
      end
    end
    
    respond_to do |format|
      format.html { render :partial => "comments/comments", :locals => { :commentable => @question } }
      format.xml { render :xml => @question.comments.to_xml }
    end
  end
  
  # POST /questions/1;rate
  # POST /questions/1.xml;rate
  def rate
    Rating.delete_all(["rateable_type = ? AND rateable_id = ? AND user_id = ?", @question.class.to_s, @question.id, current_user.id])
    
    @question.ratings << Rating.create(:user => current_user, :rating => params[:rating])
    
    respond_to do |format|
      format.html { 
        render :update do |page|
          page.replace_html "ratings_inner", :partial => "contributions/ratings_box_inner", :locals => { :contributable => @question, :controller_name => controller.controller_name }
          page.replace_html "ratings_breakdown", :partial => "contributions/ratings_box_breakdown", :locals => { :contributable => @question }
        end }
      format.xml { render :xml => @rateable.ratings.to_xml }
    end
  end
  
  # POST /questions/1;tag
  # POST /questions/1.xml;tag
  def tag
    @question.tags_user_id = current_user # acts_as_taggable_redux
    @question.tag_list = "#{@question.tag_list}, #{convert_tags_to_gem_format params[:tag_list]}" if params[:tag_list]
    @question.update_tags # hack to get around acts_as_versioned
    
    respond_to do |format|
      format.html { render :partial => "tags/tags_box_inner", :locals => { :taggable => @question, :owner_id => @question.contributor_id } }
      format.xml { render :xml => @question.tags.to_xml }
    end
  end
  
  # GET /questions
  # GET /questions.xml
  def index
    respond_to do |format|
      format.html # index.rhtml
      format.xml  { render :xml => @questions.to_xml }
      format.rss do
        #@workflows = Question.find(:all, :order => "updated_at DESC") # list all (if required)
        render :action => 'index.rxml', :layout => false
      end
    end
  end
  
  protected
  def create_question(question)
    rtn = Question.new(
                       :contributor_id => question[:contributor_id], 
                       :contributor_type => question[:contributor_type],
                       :title => question[:title])
                       
    return rtn
  end
  
  def find_questions
    login_required if login_available?
    
    found = Question.find(:all, 
                          construct_options.merge({:page => { :size => 20, :current => params[:page] }}))
    
    @questions = found
    
    found2 = Question.find(:all, :order => "created_at DESC", :limit => 30)
    
    @rss_questions = [ ]
    
    found2.each do |question|
      @rss_questions << question if question.authorized?("show", (logged_in? ? current_user : nil))
    end
  end
  
  def find_question_auth
    begin
      question = Question.find(params[:id])
      
      if question.authorized?(action_name, (logged_in? ? current_user : nil))
        @question = question
      else
        if logged_in? 
          error("Question not found (id not authorized)", "is invalid (not authorized)")
        else
          find_question_auth if login_required
        end
      end
    rescue ActiveRecord::RecordNotFound
      error("Question not found", "is invalid")
    end
  end
  
private

  def error(notice, message, attr=:id)
    flash[:notice] = notice
    (err = Question.new.errors).add(attr, message)
    
    respond_to do |format|
      format.html { redirect_to questions_url }
      format.xml { render :xml => err.to_xml }
    end
  end
  
  def construct_options
    valid_keys = ["contributor_id", "contributor_type"]
    
    cond_sql = ""
    cond_params = []
    
    params.each do |key, value|
      next if value.nil?
      
      if valid_keys.include? key
        cond_sql << " AND " unless cond_sql.empty?
        cond_sql << "#{key} = ?" 
        cond_params << value
      end
    end
    
    options = {:order => "updated_at DESC"}
    
    # added to faciliate faster requests for iGoogle gadgets
    # ?limit=0 returns all workflows (i.e. no limit!)
    options = options.merge({:limit => params[:limit]}) if params[:limit] and (params[:limit].to_i != 0)
    
    options = options.merge({:conditions => [cond_sql] + cond_params}) unless cond_sql.empty?
    
    options
  end
end