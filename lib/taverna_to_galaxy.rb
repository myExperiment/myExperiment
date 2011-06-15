# myExperiment: lib/taverna_to_galaxy.rb
# 
# Copyright (c) 2011 University of Manchester and the University of Southampton.
# See license.txt for details.

require 'zip/zip'
require 'workflow-to-galaxy'

include Generator

module TavernaToGalaxy

  def self.generate(workflow, version, t2_server, zip_file_name)

    wv = workflow.find_version(version)

    doc = XML::Document.new
    doc.root = XML::Node.new("workflow")
    doc.root << wv.components

    wkf_title   = wv.title
    wkf_descr   = wv.body
    wkf_inputs  = get_IOData(doc, "source")
    wkf_outputs = get_IOData(doc, "sink")

    w2g_workflow = W2GWorkflow.new(nil, wkf_title, wkf_descr, wkf_inputs, wkf_outputs)

    w2g_rest_object = W2GRestObject.new("#{workflow.named_download_url}?version=#{version}", w2g_workflow)

    # Set output files
    xml_file    = wv.unique_name + ".xml"
    script_file = wv.unique_name + ".rb"

    # Set taverna server if not specified
    t2_server = "http://localhost:8980/taverna-server"  if t2_server == ""

    # Generate Galaxy tool's files
    zip_file = Zip::ZipFile.open(zip_file_name, Zip::ZipFile::CREATE)

    zip_file.get_output_stream(xml_file) do |stream|
      generate_xml(w2g_rest_object, xml_file, stream)
    end

    zip_file.get_output_stream(script_file) do |stream|
      generate_script(w2g_rest_object, t2_server, stream)
    end

    zip_file.close
  end

  #
  # Populate _IOData_ objects for specified type: value +source+'+ is for inputs
  # and +sink+ for outputs
  #
  def self.get_IOData(doc, type)
    io_data = []

    # Get all sources or sinks and create appropriate objects
    doc.find("//workflow/components/dataflows/dataflow[@role='top']/#{type}s/#{type}").each do |node|
      name = ''
      descriptions = []
      examples = []

      node.each_element do |n|
        if n.name.eql? "name"
          name = n.children[0].to_s
        elsif n.name.eql? "descriptions"
          n.each_element do |d|
            descriptions << d.children[0].to_s
          end if n.children?
        elsif n.name.eql? "examples"
          n.each_element do |e|
            examples << e.children[0].to_s
          end if n.children?
        end
      end

      io_data << W2GIOData.new(name, descriptions, examples)
    end

    io_data
  end

  class W2GRestObject

    attr_reader(:uri, :workflow)

    def initialize(uri, workflow)
      @uri      = uri
      @workflow = workflow
    end

  end

  #
  # Contains all available information about a workflow: _xml_uri_, _title_, _description_,
  # _inputs_ and _outputs_. The _xml_uri_ specifies the XML description on myExperiment and
  # not the XML of the workflow itself.
  #
  class W2GWorkflow

    attr_reader(:xml_uri, :title, :description, :inputs, :outputs)

    def initialize(xml_uri, title, description, inputs, outputs)
      @xml_uri     = xml_uri
      @title       = title
      @description = description
      @inputs      = inputs
      @outputs     = outputs
    end

  end

  #
  # Contains all available information about an input or output: name, descriptions
  # and examples. The last two are lists.
  #--
  # Currently both inputs and outputs contain the same information. If that
  # changes we can subclass this one.
  #
  class W2GIOData

    attr_reader(:name, :descriptions, :examples)

    def initialize(name, descriptions, examples)
      @name         = name
      @descriptions = descriptions
      @examples     = examples
    end

  end

end

