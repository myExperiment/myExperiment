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

module WorkflowHelper
  # Access Control Layer (4 bits)
  # MSB all? friends? sharing_users? sharing_projects? LSB
  def get_acl
    all, friends, users, projects = 0, 0, 0, 0
    total = @workflow.acl_r
    
    while total > 0 do
      if total >= 8
        all = 8
        total -= 8
      elsif total >= 4
        friends = 4
        total -= 4
      elsif total >= 2
        users = 2
        total -= 2
      elsif total >= 1
        projects = 1
        total -= 1
      else
        # do nothing
      end
    end
    
    return all, friends, users, projects, (all.to_i + friends.to_i + users.to_i + projects.to_i)
  end
  
  def result_title(workflow, query)
    title = ''
    if query and not query.blank?
      title = workflow.highlight query, :field => 'title', :excerpt_length => 75, :num_excerpts => 2
    end
    if title.blank?
      title = truncate h(workflow.title), 150
    end
    title
  end
  
  def result_description(workflow, query)
    description = ''
    if query and not query.blank?
      description = workflow.highlight query, :field => 'description', :excerpt_length => 75, :num_excerpts => 3
    end
    if description.blank?
      description = truncate h(workflow.description), 225
    end
    description
  end
  
  def result_tags(workflow, query)
    tags = ''
    if query and not query.blank?
      tags = workflow.highlight query, :field => 'tag_list', :excerpt_length => 25, :num_excerpts => 3
    end
    if tags.blank?
      tags = truncate h(workflow.tag_list), 75
    end
    tags
  end
  
end
