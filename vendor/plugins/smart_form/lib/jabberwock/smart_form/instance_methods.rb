module Jabberwock # :nodoc:
  module SmartForm # :nodoc:
    module InstanceMethods
      # Generates form fields for a model - including it's content columns, and all association reflections.
      # The form fields are encapsulated in an HTML definition list.
      #
      # For an example style-sheet, you may use:
      #   <tt>ruby ./script/generate SmartFormStyles</tt>
      #
      # =Note:
      # +smart_form_for+ generates only the +form+ fields and not the starting/ending +form+ tags. 
      #
      # ==Usage:
      # smart_form_for(symbol, options)
      #
      # ==Examples:
      #   <% form_for "/people", :method => :post do %>
      #     <%= smart_form_for :person %>
      #   <% end %>
      # 
      # ==Other Examples:
      #   <%= smart_form_for :person, :exclude => 'created_at' %>
      #   <%= smart_form_for :person, :exclude => ['created_at', 'updated_at'], :class => 'my_list', :style => 'border:1px solid white;', :id => 'my_list' %>
      #
      # ==Options
      # * <tt>symbol</tt>              -- A symbol of a model instance variable for which the form fields will be generated. 
      # * <tt>:object</tt>             -- Takes an instance variable (ie; used to load form defaults for editing)
      # * <tt>:habtm_select_values</tt>-- A hash in which each key is a habtm reflection name and the value is the foreign column to use for
      #                                   the select/multiple option values. By default, the first column of type +text+ or +varchar+ is used.
      # * <tt>:exclude</tt>            -- A +String+, or an +Array+ of column names (or associatin reflection(s)) to exclude from the form.
      # * <tt>:include</tt>            -- A +String+, or an +Array+ of column names which would not otherwise be included in the model's +content_columns+. 
      #                                   For example, an 'orders' table  might contain a 'transaction_id' column which refers to an Authorize.NET 
      #                                   transaction ID, and not a foreign key to a 'transactions' table. Because this column ends with "_id", it 
      #                                   will not be in the models content columns. Use this option to display form fields for these types of columns. 
      # * <tt>:class</tt>              -- The +class+ attribute for the +DL+ element (defaults to "+smart_form+").
      # * <tt>:text_field</tt>         -- HTML options for text +input+ fields.
      # * <tt>:number_text_field</tt>  -- HTML options for text +input+ fields that deal with numbers (ie: decimal, float, integer)
      # * <tt>:text_area</tt>          -- HTML options for +textarea+ elements
      # * <tt>:select</tt>             -- Options for +select+ (default: :include_blank => true). Also contains an :@sf_html hash of HTML options to pass.
      # * <tt>:date_select</tt>        -- HTML options for +date_select+ 
      # * <tt>:datetime_select</tt>    -- HTML options for +datetime_select+ 
      # * <tt>:time_select</tt>        -- HTML options for +time_select+ 
      # * <tt>:mselect</tt>            -- HTML options for +select multiple="multiple"+ boxes
      # * <tt>:mselect_footnote</tt>   -- A footnote which appears below select/multiples (default: "(crtl+click to select multiple)")
      # * <tt>:left_width</tt>         -- The width of the left column in pixels. If specified, this setting will override the style-sheet
      # * <tt>:right_width</tt>        -- The width of the right column in pixels. If specified, this setting will override the style-sheet
      def smart_form_for(obj, options = {})
        @sf_options   = DEFAULT_FORM_OPTIONS.merge(options)
        @sf_options[:exclude] = [@sf_options[:exclude]] unless @sf_options[:exclude].is_a?(Array)
        @sf_exclude   = @sf_options[:exclude] + DEFAULT_FORM_OPTIONS[:exclude] # always exclude the default excludes, by default :)
        @sf_options[:include] = [@sf_options[:include]] unless @sf_options[:include].is_a?(Array)
        @sf_include   = @sf_options[:include]
        @left_style   = (@sf_options[:left_width].to_i  == 0 ? "" : " style=\"width: #{options[:left_width]}px !Important;\"")
        @right_style  = (@sf_options[:right_width].to_i == 0 ? "" : " style=\"width: #{options[:right_width]}px !Important;\"")

        # turn all includes/excludes to strings:
        @sf_exclude.map!(&:to_s)
        @sf_include.map!(&:to_s)

        unless obj.is_a?(Symbol)
          raise ArgumentError, "The first argument to smart_form must be a symbol"
        end

        @ar_object = get_class(obj)    

        @sf_html = "" 

        # Handle all content columns of model:
        @ar_object.content_columns.each do |col|
          next if @sf_exclude.include?(col.name) # ignore columns specified in @sf_options[:exclude]
          next if col.type==:binary # ignoring binary columns
          row_for_column(obj, col)
        end

        # any column names specfied in @sf_options[:include]? if so, we'll add those to the form: 
        @sf_include.each do |v|
          # make sure the column exists in the table:
          column = @ar_object.columns.map{|c| c.name==v}
          raise ColumnNotFound, "The column `#{v}' specified in #{v} was not found in table `#{@ar_object.table_name}'" unless column
          @sf_html << "<dl class=\"#{@sf_options[:class]}\">\n"
          @sf_html << "  <dt#{@left_style}><label for=\"#{v}\">#{v.name.gsub('_',' ').camelize}:</label></dt>\n"
          @sf_html << "  <dd#{@right_style}>" + text_field(obj, v, :size => @sf_options[:mselect_size]) + "</dd>\n"
          @sf_html << "</dl>\n"
        end

        # Handle the model's reflection associations, if any:
        @ar_object.reflections.each do |name, vhash|
          next if @sf_exclude.include?(vhash.name.to_s) # skip any reflection in @sf_exclude]
          row_for_reflection(obj, vhash, options)
        end # ar_boject.reflections.each

        @sf_html << "<!-- break --><div class=\"sf_break\"></div>\n"
        @sf_html
      end # smart_form_for


      private
      # Retrieve the ActiveRecord class of a model from a symbol
      def get_class(obj)
        tmp_obj = obj.to_s      # symbol to string
        tmp_obj.gsub!('_',' ')  # replace under scores with spaces
        tmp_obj = tmp_obj.split # split on the spaces
        tmp_obj.each {|w|       # capiatlize each word
          w.capitalize!
        }
        Object.const_get(tmp_obj.join) # finally, obtain the constant and return it
      end

      # Ouputs +DL+ row for a column
      def row_for_column(obj, col)
        @sf_html << "<dl class=\"#{@sf_options[:class]}\">\n"

        # make sure the HTML label is correct for a datetime or timestamp column:
        if col.type.to_s =~ /(datetime|date|timestamp|time)/
          @sf_html << "  <dt#{@left_style}><label for=\"#{obj}_#{col.name}_1i\">#{col.name.gsub('_',' ').camelize}:</label></dt>\n"
        else
          @sf_html << "  <dt#{@left_style}><label for=\"#{obj}_#{col.name}\">#{col.name.gsub('_',' ').camelize}:</label></dt>\n"
        end

        @sf_html << "  <dd#{@right_style}>\n"

        case col.type
          when :text
            @sf_html << text_area(obj, col.name.to_sym, @sf_options[:text_area])
          when :string
            @sf_html << text_field(obj, col.name.to_sym, @sf_options[:text_field])
          when :boolean
            @sf_html << select(obj, col.name.to_sym, [[' Yes ',true], [' No ',false]], @sf_options[:select].reject{|k,v|k==:html}, @sf_options[:select][:html])
          when :integer, :decimal, :float
            @sf_html << text_field(obj, col.name.to_sym, @sf_options[:number_text_field])
          when :date
            @sf_html << date_select(obj, col.name.to_sym, @sf_options[:date_select])
          when :datetime
            @sf_html << datetime_select(obj, col.name.to_sym, @sf_options[:datetime_select])
          when :time
            @sf_html << time_select(obj, col.name.to_sym, @sf_options[:time_select])
          when :timestamp
          @sf_html << datetime_select(obj, col.name.to_sym, @sf_options[:datetime_select])
        else
          raise UnknownColumnType, "SmartForm does not know how to handle #{col.type}! Please inform the author: #{$sf_author}"
        end # case

        @sf_html << "  </dd>\n"
        @sf_html << "</dl>\n"
      end # row_for_column

      # Outputs a +DL+ row for a model's reflection
      def row_for_reflection(obj, vhash, options)
          @sf_html << "<dl class=\"#{@sf_options[:class]}\">\n"

          # get class name of the target reflection model:
          target_class = Object.const_get(vhash.class_name)

          # guess the text/varchar column to display in select/multi boxes:
          # (or use a column that the user supplied)
          target_column = target_class.guess_column_for_option_value(@sf_options[:habtm_select_values][vhash.name.to_sym])
          
         
          # create the values for the name and id attributes of the select tag:
          if vhash.options[:through] # has_many :through
            name_attr   = "#{obj}[#{vhash.options[:through].to_s.downcase.singularize}_ids][]"
            id_attr     = vhash.options[:through].to_s.singularize + "_ids"
          else
            name_attr = "#{obj}[#{vhash.name.to_s.downcase.singularize}_ids][]"
            id_attr   = "#{obj}_#{vhash.name.to_s.downcase.singularize}_ids"
          end

          # has_many :through and has_and_belongs_to_many:
          if ((vhash.macro == :has_and_belongs_to_many) or (vhash.macro == :has_many and vhash.options[:through]))
            @sf_html << "  <dt#{@left_style}><label for=\"#{id_attr}\">#{vhash.name.to_s.gsub('_',' ').camelize}:</label></dt>\n"
            @sf_html << "  <dd#{@right_style}>\n"

            # we'll pull any existing assocation records for the current
            # reflection to auto-populate the select/multiple box:
            if options[:object]
              #if vhash.options[:through] # has_many :through
              #  selected = [options[:object].send(name_attr)] 
              #else # has_and_belongs_to_many
                selected = options[:object].send("#{vhash.name}").collect{|c| c.id}
              #end
            else
              selected = []
            end

            @sf_html << "    <select name=\"#{name_attr}\" id=\"#{id_attr}\" multiple=\"multiple\" size=\"#{@sf_options[:mselect_size]}\">\n"
            @sf_html << options_from_collection_for_select(target_class.find(:all,
                                                                         :order => "#{target_column}"),
                                                                         :id,
                                                                         target_column.to_sym,
                                                                         selected)
            @sf_html << "    </select>\n"
            @sf_html << "    <br /><small>#{@sf_options[:mselect_footnote]}</small><br />\n"
            @sf_html << "  </dd>\n"
          # belongs_to
          elsif vhash.macro==:belongs_to
            @sf_html << "  <dt#{@left_style}><label for=\"#{obj}_#{vhash.name.to_s.downcase}_id\">#{vhash.name.to_s.gsub('_',' ').camelize}:</label></dt>\n"
            @sf_html << "  <dd#{@right_style}>\n"
            @sf_html << "    " +  select(obj, "#{vhash.name.to_s.downcase}_id".to_sym, target_class.find(:all).collect{|t| [t.send(target_column), t.id]},@sf_options[:select].reject{|k,v|k==:html}, @sf_options[:select][:html]) + "\n"
            @sf_html << "  </dd>\n"
          else
          end # end if vhash.macro

          @sf_html << "</dl>\n"
      end # row_for_reflection 
    end # InstanceMethods
  end # SmartForm
end # Jabberwock

