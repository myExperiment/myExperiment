# Pivot code

TOKEN_UNKNOWN         = 0x0000
TOKEN_AND             = 0x0001
TOKEN_OR              = 0x0002
TOKEN_WORD            = 0x0003
TOKEN_OPEN            = 0x0004
TOKEN_CLOSE           = 0x0005
TOKEN_STRING          = 0x0006
TOKEN_EOS             = 0x00ff

NUM_TOKENS            = 6

STATE_INITIAL         = 0x0000
STATE_EXPECT_OPEN     = 0x0100
STATE_EXPECT_STR      = 0x0200
STATE_EXPECT_EXPR_END = 0x0300
STATE_EXPECT_END      = 0x0400
STATE_COMPLETE        = 0x0500

def calculate_pivot(opts = {})

  begin
    expr = parse_filter_expression(opts[:params]["filter"], opts[:pivot_options], :active_filters => opts[:active_filters])
  rescue Exception => ex
    problem = "Problem with query expression: #{ex}"
  end

  pivot = contributions_list(opts[:params], opts[:user], opts[:pivot_options],
                             :model            => opts[:model],
                             :auth_type        => opts[:auth_type],
                             :auth_id          => opts[:auth_id],
                             :group_by         => opts[:group_by],
                             :active_filters   => opts[:active_filters],
                             :lock_filter      => opts[:locked_filters],
                             :search_models    => opts[:search_models],
                             :search_limit     => opts[:search_limit],
                             :no_pagination    => opts[:no_pagination],
                             :filters          => expr)

  [pivot, problem]
end

def parse_filter_expression(expr, pivot_options, opts = {})

  def unescape_string(str)
    str.match(/^"(.*)"$/)[1].gsub(/\\"/, '"')
  end

  return nil if expr.nil?

  state  = STATE_INITIAL
  data   = []

  begin

    tokens = expr.match(/^

          \s* (\sAND\s)         | # AND operator
          \s* (\sOR\s)          | # OR operator
          \s* (\w+)             | # a non-keyword word
          \s* (\()              | # an open paranthesis
          \s* (\))              | # a close paranthesis
          \s* ("(\\.|[^\\"])*")   # double quoted string with backslash escapes

          /ix)

    if tokens.nil?
      token = TOKEN_UNKNOWN
    else
      (1..NUM_TOKENS).each do |i|
        token = i if tokens[i]
      end
    end

    if token == TOKEN_UNKNOWN
      token = TOKEN_EOS if expr.strip.empty?
    end

    case state | token
      when STATE_INITIAL         | TOKEN_WORD   ; state = STATE_EXPECT_OPEN     ; data << { :name => tokens[0], :expr => [] }
      when STATE_EXPECT_OPEN     | TOKEN_OPEN   ; state = STATE_EXPECT_STR
      when STATE_EXPECT_STR      | TOKEN_STRING ; state = STATE_EXPECT_EXPR_END ; data.last[:expr] << tokens[0]
      when STATE_EXPECT_EXPR_END | TOKEN_AND    ; state = STATE_EXPECT_STR      ; data.last[:expr] << :and
      when STATE_EXPECT_EXPR_END | TOKEN_OR     ; state = STATE_EXPECT_STR      ; data.last[:expr] << :or
      when STATE_EXPECT_EXPR_END | TOKEN_CLOSE  ; state = STATE_EXPECT_END
      when STATE_EXPECT_END      | TOKEN_AND    ; state = STATE_INITIAL         ; data << :and
      when STATE_EXPECT_END      | TOKEN_OR     ; state = STATE_INITIAL         ; data << :or
      when STATE_EXPECT_END      | TOKEN_EOS    ; state = STATE_COMPLETE

      else raise "Error parsing query expression"
    end

    expr = tokens.post_match unless state == STATE_COMPLETE

  end while state != STATE_COMPLETE

  # validate and reduce expressions to current capabilities

  valid_filters = pivot_options["filters"].map do |f| f["query_option"] end
  valid_filters = valid_filters.select do |f| opts[:active_filters].include?(f) end

  data.each do |category|
    case category
      when :or
        raise "Unsupported query expression"
      when :and
        # Fine
      else
        raise "Unknown filter category" unless valid_filters.include?(category[:name])

        counts = { :and => 0, :or => 0 }

        category[:expr].each do |bit|
          counts[bit] = counts[bit] + 1 if bit.class == Symbol
        end

        raise "Unsupported query expression" if counts[:and] > 0 && counts[:or] > 0

        # haven't implemented 'and' within a particular filter yet
        raise "Unsupported query expression" if counts[:and] > 0

        if category[:expr].length == 1
          category[:expr] = { :terms => [unescape_string(category[:expr].first)] }
        else
          category[:expr] = {
              :operator => category[:expr][1],
              :terms    => category[:expr].select do |t|
                t.class == String
              end.map do |t|
                unescape_string(t)
              end
          }
        end
    end
  end

  data
end

def contributions_list(params = nil, user = nil, pivot_options = nil, opts = {})

  def escape_sql(str)
    str.gsub(/\\/, '\&\&').gsub(/'/, "''")
  end

  def build_url(params, opts, expr, parts, pivot_options, extra = {})

    query = {}

    if parts.include?(:filter)
      bits = []
      pivot_options["filters"].each do |filter|
        if !opts[:lock_filter] || opts[:lock_filter][filter["query_option"]].nil?
          if find_filter(expr, filter["query_option"])
            bits << filter["query_option"] + "(\"" + find_filter(expr, filter["query_option"])[:expr][:terms].map do |t| t.gsub(/"/, '\"') end.join("\" OR \"") + "\")"
          end
        end
      end

      if bits.length > 0
        query["filter"] = bits.join(" AND ")
      end
    end

    query["query"]        = params[:query]        if params[:query]
    query["order"]        = params[:order]        if parts.include?(:order)
    query["filter_query"] = params[:filter_query] if parts.include?(:filter_query)

    query.merge!(extra)

    query
  end

  def comparison(lhs, rhs)
    if rhs.length == 1
      "#{lhs} = '#{escape_sql(rhs.first)}'"
    else
      "#{lhs} IN ('#{rhs.map do |bit| escape_sql(bit) end.join("', '")}')"
    end
  end

  def create_search_results_table(search_query, opts)

    begin
      solr_results = opts[:search_models].first.multi_solr_search(search_query,
                                                                  :models         => opts[:search_models],
                                                                  :limit          => opts[:search_limit],
                                                                  :results_format => :ids)
    rescue
      return false
    end

    conn = ActiveRecord::Base.connection

    conn.execute("CREATE TEMPORARY TABLE search_results (id INT AUTO_INCREMENT UNIQUE KEY, result_type VARCHAR(255), result_id INT)")

    # This next part converts the search results to SQL values
    #
    # from:  { "id" => "Workflow:4" }, { "id" => "Pack:6" }, ...
    # to:    "(NULL, 'Workflow', '4'), (NULL, 'Pack', '6'), ..."

    if solr_results.results.length > 0
      insert_part = solr_results.results.map do |result|
        "(NULL, " + result["id"].split(":").map do |bit|
          "'#{bit}'"
        end.join(", ") + ")"
      end.join(", ")

      conn.execute("INSERT INTO search_results VALUES #{insert_part}")
    end

    true
  end

  def drop_search_results_table
    ActiveRecord::Base.connection.execute("DROP TABLE IF EXISTS search_results")
  end

  def column(column, opts)
    if column == :auth_type
      opts[:auth_type]
    else
      column
    end
  end

  def calculate_filter(collection, params, filter, pivot_options, user, opts = {})

    # apply all the joins and conditions except for the current filter

    joins      = []
    conditions = []

    pivot_options["filters"].each do |other_filter|
      if filter_list = find_filter(opts[:filters], other_filter["query_option"])
        unless opts[:inhibit_other_conditions]
          conditions << comparison(column(other_filter["id_column"], opts), filter_list[:expr][:terms]) unless other_filter == filter
        end
        joins += other_filter["joins"] if other_filter["joins"]
      end
    end

    filter_id_column    = column(filter["id_column"],    opts)
    filter_label_column = column(filter["label_column"], opts)

    joins += filter["joins"] if filter["joins"]
    conditions << "#{filter_id_column} IS NOT NULL" if filter["not_null"]

    unless opts[:inhibit_filter_query]
      if params[:filter_query]
        conditions << "(#{filter_label_column} LIKE '%#{escape_sql(params[:filter_query])}%')"
      end
    end

    current = find_filter(opts[:filters], filter["query_option"]) ? find_filter(opts[:filters], filter["query_option"])[:expr][:terms] : []

    if opts[:ids].nil?
      limit = 10
    else
      conditions << "(#{filter_id_column} IN ('#{opts[:ids].map do |id| escape_sql(id) end.join("','")}'))"
      limit = nil
    end

    conditions = conditions.length.zero? ? nil : conditions.join(" AND ")

    count_expr = "COUNT(DISTINCT #{opts[:auth_type]}, #{opts[:auth_id]})"

    objects = collection.find(
        :all,
        :select => "#{filter_id_column} AS filter_id, #{filter_label_column} AS filter_label, #{count_expr} AS filter_count",
        :joins => merge_joins(joins, pivot_options, collection.permission_conditions, :auth_type => opts[:auth_type], :auth_id => opts[:auth_id]),
        :conditions => conditions,
        :group => "#{filter_id_column}",
        :limit => limit,
        :order => "#{count_expr} DESC, #{filter_label_column}")

    objects = objects.select do |x| !x[:filter_id].nil? end

    objects = objects.map do |object|

      value = object.filter_id.to_s
      selected = current.include?(value)

      label_expr = deep_clone(opts[:filters])
      label_expr -= [find_filter(label_expr, filter["query_option"])] if find_filter(label_expr, filter["query_option"])

      unless selected && current.length == 1
        label_expr << { :name => filter["query_option"], :expr => { :terms => [value] } }
      end

      checkbox_expr = deep_clone(opts[:filters])

      if expr_filter = find_filter(checkbox_expr, filter["query_option"])

        if selected
          expr_filter[:expr][:terms] -= [value]
        else
          expr_filter[:expr][:terms] += [value]
        end

        checkbox_expr -= [expr_filter] if expr_filter[:expr][:terms].empty?

      else
        checkbox_expr << { :name => filter["query_option"], :expr => { :terms => [value] } }
      end

      label_uri = build_url(params, opts, label_expr, [:filter, :order], pivot_options, "page" => nil)

      checkbox_uri = build_url(params, opts, checkbox_expr, [:filter, :order], pivot_options, "page" => nil)

      label = object.filter_label.clone
      label = visible_name(label) if filter["visible_name"]
      label = label.capitalize    if filter["capitalize"]

      plain_label = object.filter_label

      if params[:filter_query]
        label.sub!(Regexp.new("(#{params[:filter_query]})", Regexp::IGNORECASE), '<b>\1</b>')
      end

      {
          :object       => object,
          :value        => value,
          :label        => label,
          :plain_label  => plain_label,
          :count        => object.filter_count,
          :checkbox_uri => checkbox_uri,
          :label_uri    => label_uri,
          :selected     => selected
      }
    end

    [current, objects]
  end

  def calculate_filters(collection, params, opts, pivot_options, user)

    # produce the filter list

    filters = deep_clone(pivot_options["filters"])
    cancel_filter_query_url = nil

    filters.each do |filter|

      # calculate the top n items of the list

      filter[:current], filter[:objects] = calculate_filter(collection, params, filter, pivot_options, user, opts)

      # calculate which active filters are missing (because they weren't in the
      # top part of the list or have a count of zero)

      missing_filter_ids = filter[:current] - filter[:objects].map do |ob| ob[:value] end

      if missing_filter_ids.length > 0
        filter[:objects] += calculate_filter(collection, params, filter, pivot_options, user, opts.merge(:ids => missing_filter_ids))[1]
      end

      # calculate which active filters are still missing (because they have a
      # count of zero)

      missing_filter_ids = filter[:current] - filter[:objects].map do |ob| ob[:value] end

      if missing_filter_ids.length > 0
        zero_list = calculate_filter(collection, params, filter, pivot_options, user, opts.merge(:ids => missing_filter_ids, :inhibit_other_conditions => true))[1]

        zero_list.each do |x| x[:count] = 0 end

        zero_list.sort! do |a, b| a[:label] <=> b[:label] end

        filter[:objects] += zero_list
      end
    end

    [filters, cancel_filter_query_url]
  end

  def find_filter(filters, name)
    filters.find do |f|
      f[:name] == name
    end
  end

  def merge_joins(joins, pivot_options, permission_conditions, opts = {})
    if joins.length.zero?
      nil
    else
      joins.uniq.map do |j|
        text = pivot_options["joins"][j].clone
        text.gsub!(/RESULT_TYPE/,         opts[:auth_type])
        text.gsub!(/RESULT_ID/,           opts[:auth_id])
        text.gsub!(/VIEW_CONDITIONS/,     permission_conditions[:view_conditions])
        text.gsub!(/DOWNLOAD_CONDITIONS/, permission_conditions[:download_conditions])
        text.gsub!(/EDIT_CONDITIONS/,     permission_conditions[:edit_conditions])
        text
      end.join(" ")
    end
  end

  pivot_options["filters"] = pivot_options["filters"].select do |f|
    opts[:active_filters].include?(f["query_option"])
  end

  joins      = []
  conditions = []

  # parse the filter expression if provided.  convert filter expression to
  # the old format.  this will need to be replaced eventually

  opts[:filters] ||= []

  include_reset_url = opts[:filters].length > 0

  # filter out top level logic operators for now

  opts[:filters] = opts[:filters].select do |bit|
    bit.class == Hash
  end

  # apply locked filters

  if opts[:lock_filter]
    opts[:lock_filter].each do |filter, value|
      opts[:filters] << { :name => filter, :expr => { :terms => [value] } }
    end
  end

  # perform search if requested

  query_problem = false

  if params["query"]
    drop_search_results_table
    if !create_search_results_table(params["query"], opts)
      params["query"] = nil
      query_problem = true
    end
  end

  if params[:query]
    klass     = SearchResult
    auth_type = "search_results.result_type"
    auth_id   = "search_results.result_id"
    group_by  = "search_results.result_type, search_results.result_id"
  else
    klass     = opts[:model]     || Contribution
    auth_type = opts[:auth_type] || "contributions.contributable_type"
    auth_id   = opts[:auth_id]   || "contributions.contributable_id"
    group_by  = opts[:group_by]  || "contributions.contributable_type, contributions.contributable_id"
  end

  # determine joins, conditions and order for the main results

  pivot_options["filters"].each do |filter|
    if filter_list = find_filter(opts[:filters], filter["query_option"])
      conditions << comparison(column(filter["id_column"], opts.merge( { :auth_type => auth_type, :auth_id => auth_id } )), filter_list[:expr][:terms])
      joins += filter["joins"] if filter["joins"]
    end
  end

  order_options = pivot_options["order"].find do |x|
    x["option"] == params[:order]
  end

  order_options ||= pivot_options["order"].first

  joins += order_options["joins"] if order_options["joins"]

  having_bits = []

#   pivot_options["filters"].each do |filter|
#     if params["and_#{filter["query_option"]}"]
#       having_bits << "GROUP_CONCAT(DISTINCT #{filter["id_column"]} ORDER BY #{filter["id_column"]}) = \"#{escape_sql(opts[:filters][filter["query_option"]])}\""
#     end
#   end

  having_clause = ""

  if having_bits.length > 0
    having_clause = "HAVING #{having_bits.join(' AND ')}"
  end

  # perform the results query

  collection = Authorization.scoped(klass,
                                    :authorised_user => user,
                                    :include_permissions => true,
                                    :auth_type => auth_type,
                                    :auth_id => auth_id)

  result_options = {:joins => merge_joins(joins, pivot_options, collection.permission_conditions, :auth_type => auth_type, :auth_id => auth_id),
                    :conditions => conditions.length.zero? ? nil : conditions.join(" AND "),
                    :group => "#{group_by} #{having_clause}",
                    :order => order_options["order"]}

  unless opts[:no_pagination]
    result_options[:page] = { :size => params["num"] ? params["num"].to_i : nil, :current => params["page"] }
  end

  results = collection.find(:all, result_options)

  # produce a query hash to match the current filters

  opts[:filter_params] = {}

  pivot_options["filters"].each do |filter|
    if params[filter["query_option"]]
      next if opts[:lock_filter] && opts[:lock_filter][filter["query_option"]]
      opts[:filter_params][filter["query_option"]] = params[filter["query_option"]]
    end
  end

  # produce the filter list

  opts_for_filter_query = opts.merge( { :auth_type => auth_type,
                                        :auth_id => auth_id, :group_by => group_by } )

  filters, cancel_filter_query_url = calculate_filters(collection, params, opts_for_filter_query, pivot_options, user)

  # produce the summary.  If a filter query is specified, then we need to
  # recalculate the filters without the query to get all of them.

  if params[:filter_query]
    filters2 = calculate_filters(collection, params, opts_for_filter_query.merge( { :inhibit_filter_query => true } ), pivot_options, user)[0]
  else
    filters2 = filters
  end

  summary = ""

  filters2.select do |filter|

    next if opts[:lock_filter] && opts[:lock_filter][filter["query_option"]]

    selected = filter[:objects].select do |x| x[:selected] end
    current  = selected.map do |x| x[:value] end

    if selected.length > 0
      selected_labels = selected.map do |x|

        expr = deep_clone(opts[:filters])

        f = find_filter(expr, filter["query_option"])

        expr -= f[:expr][:terms] -= [x[:value]]
        expr -= [f] if f[:expr][:terms].empty?

        x[:plain_label] + ' <a href="' + url_for(build_url(params, opts, expr,
                                                           [:filter, :filter_query, :order], pivot_options)) +
            '">' + " <img src='/images/famfamfam_silk/cross.png' /></a>"

      end

      bits = selected_labels.map do |label| label end.join(" <i>or</i> ")

      summary << '<span class="filter-in-use"><b>' + filter["title"].capitalize + "</b>: " + bits + "</span> "
    end
  end

  if params[:filter_query]
    cancel_filter_query_url = build_url(params, opts, opts[:filters], [:filter, :order], pivot_options)
  end

  if include_reset_url
    reset_filters_url = build_url(params, opts, opts[:filters], [:order], pivot_options)
  end

  # remove filters that do not help in narrowing down the result set

  filters = filters.select do |filter|
    if filter[:objects].empty?
      false
    elsif opts[:lock_filter] && opts[:lock_filter][filter["query_option"]]
      false
    else
      true
    end
  end

  {
      :results                 => results,
      :filters                 => filters,
      :reset_filters_url       => reset_filters_url,
      :cancel_filter_query_url => cancel_filter_query_url,
      :filter_query_url        => build_url(params, opts, opts[:filters], [:filter], pivot_options),
      :summary                 => summary,
      :pivot_options           => pivot_options,
      :query_problem           => query_problem
  }
end

def visible_name(entity)
  name = entity.class.name

  if Conf.model_aliases.value?(name)
    Conf.model_aliases.each do |al, model|
      name = al if name == model
    end
  end

  name
end

