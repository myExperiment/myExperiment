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

module Dgc
  module Acts #:nodoc:
    module Creditable #:nodoc:
      def self.included(mod)
        mod.extend(ClassMethods)
      end
      
      module ClassMethods
        def acts_as_creditable
          belongs_to :creditor, :polymorphic => true
          
          class_eval do
            extend Dgc::Acts::Creditable::SingletonMethods
          end
          include Dgc::Acts::Creditable::InstanceMethods
          
        end
      end
      
      module SingletonMethods
      end
      
      module InstanceMethods

        def creditors
          return Creditation.find_all_by_creditable_id_and_creditable_type(self.id, self.class.to_s);
        end

      end
    end
  end
end

ActiveRecord::Base.class_eval do
  include Dgc::Acts::Creditable
end
