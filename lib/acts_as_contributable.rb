##
##
## myExperiment - a social network for scientists
##
## Copyright (C) 2007 University of Manchester/University of Southampton
##
## This program is free software; you can redistribute it and/or modify
## it under the terms of the GNU Affero General Public License
## as published by the Free Software Foundation; either version 3 of the
## License, or (at your option) any later version.
##
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU Affero General Public License for more details.
##
## You should have received a copy of the GNU Affero General Public License
## along with this program; if not, see http://www.gnu.org/licenses
## or write to the Free Software Foundation,Inc., 51 Franklin Street,
## Fifth Floor, Boston, MA 02110-1301  USA
##
##

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
                  
          acts_as_bookmarkable
          acts_as_commentable
          acts_as_rateable
          acts_as_taggable
                  
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
