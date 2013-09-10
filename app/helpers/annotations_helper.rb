# myExperiment: app/helpers/annotations_helper.rb
#
# Copyright (c) 2007-2013 The University of Manchester, the University of
# Oxford, and the University of Southampton.  See license.txt for details.

module AnnotationsHelper

  def wfprov_workflow_run(research_object)
    graph = research_object.merged_annotation_graphs

    workflows = graph.query([nil, RDF.type, RDF::URI("http://purl.org/wf4ever/wfprov#WorkflowRun")]).subjects

    select_options = workflows.map do |workflow|
      [graph.query([workflow, RDF::RDFS.label, nil]).first_literal.to_s, workflow.to_s]
    end
  end

end
