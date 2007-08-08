#
#
# Copyright (c) 2007, Mark Borkum (mib104@ecs.soton.ac.uk)
#
# Permission is hereby granted, free of charge, to any person
# obtaining a copy of this software and associated documentation
# files (the "Software"), to deal in the Software without
# restriction, including without limitation the rights to use,
# copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following
# conditions:

# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
# OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
# HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
# WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
# OTHER DEALINGS IN THE SOFTWARE.
# 
# 

module Mib
  module Acts #:nodoc:
    module Contributor #:nodoc:
      def self.included(mod)
        mod.extend(ClassMethods)
      end
      
      module ClassMethods
        def acts_as_contributor
          has_many :contributions, :as => :contributor
          has_many :policies, :as => :contributor
          has_many :permissions, :as => :contributor
          
          class_eval do
            extend Mib::Acts::Contributor::SingletonMethods
          end
          include Mib::Acts::Contributor::InstanceMethods
        end
      end
      
      module SingletonMethods
        # def find_by_contributable(contributable, options = {})
        #   find_by_contributable_id_and_contributable_type(contributable.id, contributable.class.to_s, options)
        # end
          
        # def find_by_contributable_id_and_contributable_type(contributable_id, contributable_type, options = {})
        #   # protect the original sql statement
        #   options.delete(:select) if options[:select]
        #   options.delete(:joins) if options[:joins]
        #   
        #   select_columns = ""
        #   columns.each do |c|
        #     select_columns << ", " unless select_columns.empty?
        #     select_columns << "#{table_name}.#{c.name}"
        #   end
        #   
        #   find(:first, { :select => select_columns, 
        #                  :joins => "LEFT OUTER JOIN contributions ON contributions.contributable_id = #{contributable_id} AND contributions.contributable_type = '#{contributable_type}'"}.merge(options))
        # end
      end
      
      module InstanceMethods
        # extend in instance class
        def related?(other)
          false
        end
      end
    end
  end
end

ActiveRecord::Base.class_eval do
  include Mib::Acts::Contributor
end