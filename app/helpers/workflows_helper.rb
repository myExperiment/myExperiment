# myExperiment: app/helpers/workflows_helper.rb
#
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

require 'openurl'

module WorkflowsHelper
  
  def workflow_types
    types = WorkflowTypesHandler.types_list
    types.sort! {|x,y| x.downcase <=> y.downcase}
    types << "Other"
  end
  
  def get_type_dir(workflow_version)
    klass = workflow_version.processor_class
    return (klass.nil? ? "other" : h(klass.to_s.demodulize.underscore))
  end
  
  def workflow_context_object(workflow)

    co = OpenURL::ContextObject.new

    co.referent.set_metadata('title', workflow.title)
    co.referent.set_metadata('date', workflow.created_at.strftime("%Y-%m-%d"))
    co.referent.set_metadata('au', workflow.contributor.name)
    co.referent.set_metadata('genre', 'unknown')

    co.referent.set_format("dc")

    html_escape(co.kev)
  end

  def online_hpc_url(workflow = nil)
    if workflow.nil?
      Conf.online_hpc_url
    else
      if workflow.is_a?(Workflow)
        id = workflow.id
      elsif workflow.is_a?(Fixnum)
        id = workflow
      end

      url = URI.parse(Conf.online_hpc_url)
      url.query = [url.query, "workflowId=#{id}"].compact.join('&')
      url.to_s
    end
  end

  def workflow_processor_details(configuration)
    comp = configuration.delete(:component)

    html = ''

    configuration.each do |key, value|
      html << "<div><h3>#{key.to_s.titleize}</h3>"
      if [:script, :xpath_expression].include?(key)
        html << "<pre>#{value}</pre>"
      elsif key == :interaction_page
        html << "<a href=\"#{value}\">#{value}</a>"
      else
        html << "#{value}"
      end
      html << '</div>'
    end

    html << component_details(comp) if comp

    html
  end

  private

  def component_details(hash)
    if internal_resource_uri?(hash[:registry])
      component = WorkflowVersion.find_by_title_and_version(hash[:name], hash[:version])
      link = component ? link_to(hash[:name], workflow_path(component.workflow, :version => component.version)) : hash[:name]
      "<div><h3>Component</h3>#{link}</div>"
    else
      "<div><h3>External Component</h3>#{hash[:name]} v#{hash[:version]}</div>"
    end
  end

end
