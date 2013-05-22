# myExperiment: lib/taverna_to_galaxy.rb
# 
# Copyright (c) 2011 University of Manchester and the University of Southampton.
# See license.txt for details.

require 'zip/zip'
require 'workflow-to-galaxy'
require 'myexperiment-rest'

module TavernaToGalaxy

  def self.generate(workflow, version, t2_server, zip_file_name)

    wv = workflow.find_version(version)

    doc = XML::Document.new

    doc.root = XML::Node.new("workflow")

    doc.root << (XML::Node.new("title") << wv.title)
    doc.root << (XML::Node.new("description") << wv.body)
    doc.root << (XML::Node.new("content-uri") << workflow.named_download_url)
    doc.root << (XML::Node.new("uploader")    << workflow.contributor.label)

    doc.root << wv.components

    response = MyExperimentREST::MyExperimentWorkflow.parse(doc.root.to_s)

    # Set output files
    xml_file = wv.unique_name + ".xml"
    rb_file  = wv.unique_name + ".rb"

    # Set taverna server if not specified
    t2_server = "http://localhost:8980/taverna-server"  if t2_server == ""

    # Generate Galaxy tool's files
    zip_file = Zip::ZipFile.open(zip_file_name, Zip::ZipFile::CREATE)

    zip_file.get_output_stream(xml_file) do |xml_stream|
      zip_file.get_output_stream(rb_file) do |rb_stream|

        tool = WorkflowToGalaxy::GalaxyTool.new(
          :wkf_source => WorkflowToGalaxy::Workflows::MYEXPERIMENT_TAVERNA2,
          :params => {
            :t2_server => t2_server,
            :xml_out   => xml_stream,
            :rb_out    => rb_stream,
            :response  => response })

        tool.generate
      end
    end

    zip_file.close
  end
end

