module Jabberwock # :nodoc:
  module SmartForm # :nodoc:    
    module ClassMethods
      # Attempts to guess which column to use for HTML select +option+ values.
      # Intended to be used for select-multiple boxes in HABTM relationships.
      # Returns the first column of type +:string+ or +:text+,
      # or nil if none are found. Takes an optional argument, which should be a
      # column name for that model. If an argument is supplied, and that column exists,
      # it is immediately returned. If the supplied argument does not exist, an exception
      # will be raised.
      #
      # ==Examples:
      # Given the table `tags` with the columns `id`(int)  and `tag`(varchar):
      #   Tag.guess_column_for_option_value => "tag"
      #   Tag.guess_column_for_option_value("tag")  => "tag"
      #   Tag.guess_column_for_option_value("foo")  => ColumnNotFound
      #
      # Author:: Jabberwock (jabberwock /AT tenebrous /DOT com)
      # Copyright:: Copyright(c) 2007 Jabberwock
      def guess_column_for_option_value(col=nil)
        unless col.nil?
          return col.to_s if self.new.respond_to?(col.to_sym)
          raise ColumnNotFound, "Column `#{col}' was not found in table `#{self.table_name}'"
        end
        self.columns.collect{|col| col.name if col.type.to_s =~ /^(string|text)$/}.compact[0]
      end
   
      # Obtains the target table of an ActiveRecord reflection
      #
      # ==Examples:
      #
      # Person.get_table_name_from_reflection(Tag)
      def get_table_name_from_reflection(ref) 
        table = nil
        case ref.macro
          when :has_many
            if ref.through_reflection
              table = ref.through_reflection.table_name
            else
              table = ref.table_name
            end
          when :has_and_belongs_to_many
            table = ref.options[:join_table]
          when :belongs_to
            if ref.through_reflection
              table = ref.through_reflection.table_name
            else
              table = ref.table_name
            end
          else
            table = ref.table_name
        end # case
        table
      end # get_table_name_from_reflection
    end # ClassMethods
  end # SmartForm
end # Jabberwock
