# myExperiment: vendor/plugins/structured_data/lib/auto_migrate.rb
#
# Copyright (c) 2009 University of Manchester and the University of Southampton.
# See license.txt for details.

require 'xml/libxml'

class AutoMigrate

  AUTO_TABLE_NAME     = "auto_tables"
  SCHEMA              = "config/base_schema.xml"
  SCHEMA_D            = "config/schema.d"
  COLUMN_ATTRIBUTES     = ['name', 'type', 'default', 'limit']
  BELONGS_TO_ATTRIBUTES = ['polymorphic', 'class_name', 'foreign_key']
  HAS_MANY_ATTRIBUTES   = ['target', 'through', 'foreign_key', 'source', 'dependent', 'conditions', 'class_name', 'as']

  def self.schema

    tables  = {}
    assocs  = []
    indexes = {}

    # load the base schema

    if File.exists?(SCHEMA)
      tables, assocs, indexes = merge_schema(File.read(SCHEMA), tables, assocs, indexes) 
    end

    # merge files from the schema directory

    if File.exists?(SCHEMA_D)

      Dir.new(SCHEMA_D).each do |entry|
        if entry.ends_with?(".xml")
          tables, assocs, indexes = merge_schema(File.read("#{SCHEMA_D}/#{entry}"), tables, assocs, indexes)
        end
      end
    end

    [tables, assocs, indexes]
  end

  def self.migrate

    def self.column_default(column)
      if column['default']
        case column['type']
        when 'boolean'
          return false if column['default'] == 'false'
          return true  if column['default'] == 'true'
          raise "Default values for boolean types must be either 'true' or 'false'"
        else
          column['default'].to_s
        end
      end
    end

    conn = ActiveRecord::Base.connection

    # ensure that the auto_tables table exists
    
    tables = conn.tables

    if tables.include?(AUTO_TABLE_NAME) == false
      conn.create_table(AUTO_TABLE_NAME) do |table|
        table.column :name,   :string
        table.column :schema, :text
      end
    end

    old_tables = AutoTable.find(:all).map do |table| table.name end
       
    # get the schema

    new_tables, assocs, indexes = schema

    # create and drop tables as appropriate

    (old_tables - new_tables.keys).each do |name|
      conn.drop_table(name)
      AutoTable.find_by_name(name).destroy
    end 

    (new_tables.keys - old_tables).each do |name|
      unless tables.include?(name)
        conn.create_table(name) do |table| end
      end
      AutoTable.create(:name => name)
    end

    # adjust the columns in each table

    new_tables.keys.each do |table_name|

      # get the list of existing columns

      old_columns = conn.columns(table_name).map do |column| column.name end - ["id"]

      # and get detailed information about the existing columns

      old_column_info = {}
      
      conn.columns(table_name).each do |c|
        old_column_info[c.name] = c
      end

      # determine the required columns

      new_columns = new_tables[table_name][:columns].map do |column, definition| column end

      # remove columns

      (old_columns - new_columns).each do |column_name|
        conn.remove_column(table_name, column_name)
      end

      # add columns

      (new_columns - old_columns).each do |column_name|
        default = column_default(new_tables[table_name][:columns][column_name])
        conn.add_column(table_name, column_name, new_tables[table_name][:columns][column_name]["type"].to_sym, :default => default, :limit => new_tables[table_name][:columns][column_name]['limit'])
      end

      # modify existing columns

      (old_columns & new_columns).each do |column_name|

        old_default = old_column_info[column_name].default
        new_default = column_default(new_tables[table_name][:columns][column_name])

        old_default = old_default.to_s unless old_default.nil?
        new_default = new_default.to_s unless new_default.nil?

        old_type    = old_column_info[column_name].type
        new_type    = new_tables[table_name][:columns][column_name]['type'].to_sym

        if (old_default != new_default) || (old_type != new_type)
          conn.change_column(table_name.to_sym, column_name.to_sym, new_type, :default => new_default)
        end
      end

      # get the list of existing indexes

      old_indexes = conn.indexes(table_name).map do |index| [index.columns] end

      # determine the required indexes

      new_indexes = indexes[table_name]

      # remove indexes

      (old_indexes - new_indexes).each do |to_remove|
        conn.indexes(table_name).select do |index| to_remove == [index.columns] end.each do |index|
          conn.remove_index(table_name, index.columns)
        end
      end

      # add indexes

      (new_indexes - old_indexes).each do |index|
        conn.add_index(table_name, index[0])
      end
    end

    # now that the schema has changed, load the models

    load_models(new_tables)
  end

  def self.destroy_auto_tables

    conn   = ActiveRecord::Base.connection
    tables = conn.tables
    
    AutoTable.find(:all).map do |table|
      conn.drop_table(table.name)
    end

    conn.drop_table(AUTO_TABLE_NAME) if tables.include?(AUTO_TABLE_NAME)
  end

private

  def self.merge_schema(schema, tables = {}, assocs = [], indexes =  {})

    root = LibXML::XML::Parser.string(schema).parse.root

    root.find('/schema/table').each do |table|

      tables[table['name']] ||= { :columns => {} }

      if table['class_name']
        tables[table['name']][:class_name] = table['class_name']
      end

      table.find('column').each do |column|
        tables[table['name']][:columns][column['name']] ||= {}

        COLUMN_ATTRIBUTES.each do |attribute|
          if column[attribute] and attribute != 'name'
            tables[table['name']][:columns][column['name']][attribute] = column[attribute]
          end
        end
      end

      table.find('belongs-to').each do |belongs_to|
        attributes = {:table => table['name'], :type => 'belongs_to', :target => belongs_to['target']}

        BELONGS_TO_ATTRIBUTES.each do |attribute|
          attributes[attribute.to_sym] = belongs_to[attribute] if belongs_to[attribute]
        end

        assocs.push(attributes)
      end

      table.find('has-many').each do |has_many|
        attributes = {:table => table['name'], :type => 'has_many'}

        HAS_MANY_ATTRIBUTES.each do |attribute|
          attributes[attribute.to_sym] = has_many[attribute] if has_many[attribute]
        end

        assocs.push(attributes)
      end

      indexes[table['name']] ||= []

      table.find('index').each do |index|
        indexes[table['name']].push([index.find('column').map do |column| column['name'] end])
      end
    end

    [tables, assocs, indexes]
  end

  def self.get_model(name)

    c = Object

    name.split("::").each do |bit|
      c = c.const_get(bit)
    end

    c
  end

  def self.set_model(name, c)

    container = Object
    bits = name.split("::")
    
    bits[0..-2].each do |bit|
      container = container.const_get(bit)
    end

    container.const_set(bits[-1].to_sym, c)
  end

  def self.load_models(tables)
    tables.each do |table, options|

      class_name = table.singularize.camelize

      class_name = options[:class_name] if options[:class_name]

      begin
        get_model(class_name)
      rescue NameError

        # logger.info("Structured data: instantiating #{class_name}")

        # model object not defined.  create it

        c = Class.new(ActiveRecord::Base)
        c.class_eval("acts_as_structured_data(:class_name => '#{class_name}')")

        set_model(class_name, c)
      end
    end
  end
end

