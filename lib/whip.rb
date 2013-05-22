#
#  Whip.rb
#  
#
#  This module requires rubyzip and libxml 0.6.0 at least
#  on Mac, you may need to update your version of libxml2 as well, for example using macport or fink. 
#

#!/usr/bin/env ruby

require 'zip/zip'
require 'xml/libxml'

module Whip

	SchemeDataType = "http://org.whipplugin/data/description/datatype"
	SchemeEntryPoint = "http://org.whipplugin/data/description/entrypoint"
	TermInstaller = "urn:org.whipplugin:data:description:installer"
	SchemeWorkflowID = "#{Conf.base_uri}/workflows/workflowid"
	SchemeVersion = "#{Conf.base_uri}/workflows/version"
	# datatype used to identify Taverna 1.7 compatible scufl
	Taverna1DataType = "http://org.embl.ebi.escience/xscufl/0.1alpha"
	EntryIDPrefix = "#{Conf.base_uri}/workflows/"
	AtomDateFormat = "%Y-%m-%dT%H:%M:%SZ"
	
	# 
	# fileName method.
	# takes a WhipWorkflow object and a base directory and returns the file
	# path to the bundle.
	#
	# returns a string containing the file path of the bundle.
	#
	def Whip.filePath(whip_workflow, target_dir)
		target_dir = checkDir(target_dir)
		fname = whip_workflow.workflow_id + "_" + whip_workflow.version + ".whip"
		target_dir + fname;
	end

	#
	# bundle method.
	# takes a WhipWorkflow object and a base directory into which the generated
	# bundle will be created.
	#
	# returns a WhipBundle object
	#
	def Whip.bundle(whip_workflow, target_dir)
		if !verifyWorkflow(whip_workflow)
			logger.debug("workflow does not contain enough attributes to be processed")
			return nil
		end
		entry = createMetadata(whip_workflow)
		file_path = Whip::filePath(whip_workflow, target_dir)
		if File.exists? file_path
			File.delete file_path
		end
		zip_file = Zip::ZipFile.open(file_path, Zip::ZipFile::CREATE);
		zip_file.get_output_stream("metadata.xml") { |stream| stream.puts(entry.to_s)}
		zip_file.mkdir("data")
		zip_file.get_output_stream("data/" + whip_workflow.name) { |stream| stream.write(whip_workflow.data)}
		zip_file.close()
		file = File.new(file_path)
		return WhipBundle.new(file)
	end
	
	def Whip.createMetadata(whip_workflow)
		doc = XML::Document.new()
        doc.root = XML::Node.new("entry")
		doc.root["xmlns"] = "http://www.w3.org/2005/Atom"
        root = doc.root
		root << title = XML::Node.new("title")
        title << whip_workflow.title
		root << createPerson("author", whip_workflow.author)
		wfhref = EntryIDPrefix + whip_workflow.workflow_id + "?version=" + whip_workflow.version
		root << id = XML::Node.new("id")
        id << wfhref
		root << alt = XML::Node.new("link")
        alt["href"] = wfhref
		alt["rel"] = "alternate"
		root << up = XML::Node.new("updated")
        up << whip_workflow.updated.strftime(AtomDateFormat)
		root << sum = XML::Node.new("summary")
        sum << whip_workflow.summary
		root << createCategory(SchemeDataType, whip_workflow.datatype, "The datatype the application is interested in")
		root << createCategory(SchemeEntryPoint, whip_workflow.name, "The entry point for the application")
		root << createCategory(SchemeWorkflowID, whip_workflow.workflow_id, "Workflow Identifier")
		root << createCategory(SchemeVersion, whip_workflow.version, "Workflow Version")
		root << content = XML::Node.new("content")
		content["type"] = "xhtml"
		content << createContent(whip_workflow.name)
		return doc
	end

	def Whip.createContent(name)
		div = XML::Node.new("div")
		div["xmlns"] = "http://www.w3.org/1999/xhtml"
		div["class"] = "whip-content"
		div << inner = XML::Node.new("div")
		inner["class"] = "entry-point"
		inner << name
		return div
	end
	
	def Whip.createCategory(scheme, term, label)
		cat = XML::Node.new("category")
		cat["scheme"] = scheme
		cat["term"] = term
		cat["label"] = label
		return cat
	end
	
	def Whip.createPerson(type, name)
		p = XML::Node.new(type)
		p << n = XML::Node.new("name")
		n << name
		return p
	end
	
	def Whip.checkDir(dir)
		if dir.rindex("/") != dir.length - 1
			return dir + "/"
		end
		return dir
	end
	
	def Whip.verifyWorkflow(wf)
		return wf.instance_variable_defined?("@name") &&
		wf.instance_variable_defined?("@title") &&
		wf.instance_variable_defined?("@summary") &&
		wf.instance_variable_defined?("@author") &&
		wf.instance_variable_defined?("@data") &&
		wf.instance_variable_defined?("@datatype") &&
		wf.instance_variable_defined?("@updated") &&
		wf.instance_variable_defined?("@workflow_id") &&
		wf.instance_variable_defined?("@version")
	end
	
	#
	# container class passed to the bundle method
	#
	# name			>> the zip entry name that should be used for the workflow description (e.g. my_workflow.xml)
	#				Please remember that this may end up being used as a file name, so should be compatible with such use
	# title			>> the title of the bundle. This will be used as the title for the metadata
	# summary		>> a summary of the workflow
	# author		>> author of the workflow
	# data			>> the workflow itself, as a string
	# datatype		>> datatype of the workflow description. This is used by WHIP to map data to applications
	# updated		>> a Time object representing when the workflow was last updated
	# workflow_id	>> the id of the workflow.
	# version		>> the version of the workflow
	#
	# These last two are used to generate the bundle name "{workflow_id}_{version}.whip"
	# as well as the Atom entry's id field, which is actually the MyExperiment URL for the workflow:
	#
	#		"http://www.myexperiment.org/workflows/{workflow_id}?version={version}"
	#
	# They are also stored in the Atom entry as categories
	#
	class WhipWorkflow
		attr_accessor :name, :title, :summary, :author, :data, :datatype, :updated, :workflow_id, :version
	end
	
	#
	# wrapper around a File object. Will have more functionality at some point.
	# currently you can get the file itself, and it extracts the metadata
	# once metadata() is called, the bundle will hold an in memory XML document 
	# representing the metadata.
	#
	class WhipBundle
		def initialize(file)
			@file = file
			@atom_entry = nil
		end
		
		def name
			return File.basename(@file.path)
		end
		
		def path
			return @file.path
		end
		
		def metadata
			if @atom_entry
				return @atom_entry.to_s
			end
			zipfile = Zip::ZipFile.open(path);
			entry = zipfile.read("metadata.xml")
			zipfile.close()
			p = XML::Parser.string(entry)
			@atom_entry = p.parse
			return @atom_entry.to_s			
		end
				
		def file
			return @file
		end
	end

end
