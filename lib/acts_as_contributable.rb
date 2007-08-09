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
    module Contributable #:nodoc:
      def self.included(mod)
        mod.extend(ClassMethods)
      end
      
      module ClassMethods
        def acts_as_contributable
          belongs_to :contributor, :polymorphic => true
          
          has_one :contribution, 
                  :as => :contributable,
                  :dependent => :destroy
          
          class_eval do
            extend Mib::Acts::Contributable::SingletonMethods
          end
          include Mib::Acts::Contributable::InstanceMethods
          
          before_create do |c|
            c.contribution = Contribution.new(:contributor_id => c.contributor_id, :contributor_type => c.contributor_type, :contributable => c)
          end
        end
      end
      
      module SingletonMethods
        def find_all_by_contributor(contributor, options = {})
          find_all_by_contributor_id_and_contributor_type(contributor.id, contributor.class.to_s, options)
        end
        
        def find_all_by_contributor_id_and_contributor_type(contributor_id, contributor_type, options = {})
          # protect the original sql statement
          options.delete(:select) if options[:select]
          options.delete(:joins) if options[:joins]
          
          select_columns = ""
          columns.each do |c|
            select_columns << ", " unless select_columns.empty?
            select_columns << "#{table_name}.#{c.name}"
          end
          
          find(:all, { :select => select_columns, 
                       :joins => "LEFT OUTER JOIN contributions ON contributions.contributor_id = #{contributor_id} AND contributions.contributor_type = '#{contributor_type}'"}.merge(options))
        end
      end
      
      module InstanceMethods
        def authorized?(action_name, contributor=nil)
          contribution.authorized?(action_name, contributor)
        end
      end
    end
  end
end

ActiveRecord::Base.class_eval do
  include Mib::Acts::Contributable
end