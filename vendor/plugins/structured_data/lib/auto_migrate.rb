# myExperiment: vendor/plugins/structured_data/lib/auto_migrate.rb
#
# Copyright (c) 2009 University of Manchester and the University of Southampton.
# See license.txt for details.

require 'xml/libxml'

class AutoMigrate

  AUTO_TABLE_NAME     = "auto_tables"
  SCHEMA              = "config/base_schema.xml"
  SCHEMA_D            = "config/schema.d"
  COLUMN_ATTRIBUTES   = ['name', 'type']
  HAS_MANY_ATTRIBUTES = ['target', 'through', 'foreign_key']

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
      conn.create_table(name) do |table| end
      AutoTable.create(:name => name)
    end

    # adjust the columns in each table

    new_tables.keys.each do |table_name|

      # get the list of existing columns

      old_columns = conn.columns(table_name).map do |column| column.name end - ["id"]

      # determine the required columns

      new_columns = new_tables[table_name].map do |column, definition| column end

      # remove columns

      (old_columns - new_columns).each do |column_name|
        conn.remove_column(table_name, column_name)
      end

      # add columns

      (new_columns - old_columns).each do |column_name|
        conn.add_column(table_name, column_name, new_tables[table_name][column_name]["type"].to_sym)
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

    # adjust the indexes in each table

    new_tables.keys.each do |table_name|
    end

    # now that the schema has changed, load the models

    load_models(new_tables.keys)
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
      tables[table['name']] ||= {}

      table.find('column').each do |column|
        tables[table['name']][column['name']] ||= {}

        COLUMN_ATTRIBUTES.each do |attribute|
          if column[attribute] and attribute != 'name'
            tables[table['name']][column['name']][attribute] = column[attribute]
          end
        end
      end
    end

    root.find('/schema/table').each do |table|
      table.find('belongs-to').each do |belongs_to|
        assocs.push(:table => table['name'], :type => 'belongs_to', :target => belongs_to['target'])
      end

      table.find('has-many').each do |has_many|
        attributes = {:table => table['name'], :type => 'has_many'}

        HAS_MANY_ATTRIBUTES.each do |attribute|
          attributes[attribute.to_sym] = has_many[attribute] if has_many[attribute]
        end

        assocs.push(attributes)
      end
    end

    root.find('/schema/table').each do |table|

      indexes[table['name']] ||= []

      table.find('index').each do |index|
        indexes[table['name']].push([index.find('column').map do |column| column['name'] end])
      end
    end

    [tables, assocs, indexes]
  end

  def self.load_models(tables)
    tables.each do |table|

      class_name = table.singularize.camelize

      begin
        Object.const_get(class_name)
      rescue NameError

        # model object not defined.  create it

        c = Class.new(ActiveRecord::Base)
        c.class_eval("acts_as_structured_data(:class_name => '#{class_name}')")

        Object.const_set(class_name.to_sym, c)
      end
    end
  end
end

