# myExperiment: lib/static_oai.rb
#
# Copyright (c) 2009 University of Manchester and the University of Southampton.
# See license.txt for details.

require 'xml/libxml'

include LibXML::XML

module OAIStaticRepository

  def self.generate_workflow_id(workflow)
    "oai:myexperiment.org:workflow/#{workflow.id}"
  end

  def self.generate(workflows)

    def self.build(name, text = nil, &blk)
      node = Node.new(name)
      node << text if text
      yield(node) if blk
      node
    end

    if workflows.length > 0
      earliest_datestamp = workflows.first.created_at
      workflows.each do |w|
        earliest_datestamp = w.created_at if w.created_at < earliest_datestamp
      end
    end

    repository_name    = "myExperiment"
    base_url           = "http://www.myexperiment.org/oai/static.xml"
    protocol_version   = "2.0"
    admin_email        = "dgc@ecs.soton.ac.uk"
    deleted_record     = "no"

    doc = Document.new

    doc.root = build("Repository") { |repository|

      repository["xmlns"]              = "http://www.openarchives.org/OAI/2.0/static-repository" 
      repository["xmlns:oai"]          = "http://www.openarchives.org/OAI/2.0/" 
      repository["xmlns:xsi"]          = "http://www.w3.org/2001/XMLSchema-instance" 
      repository["xsi:schemaLocation"] = "http://www.openarchives.org/OAI/2.0/static-repository " +
                                "http://www.openarchives.org/OAI/2.0/static-repository.xsd"

      repository << build("Identify") { |identify|

        identify << build("oai:repositoryName",    repository_name)
        identify << build("oai:baseURL",           base_url)
        identify << build("oai:protocolVersion",   protocol_version)
        identify << build("oai:adminEmail",        admin_email)
        identify << build("oai:earliestDatestamp", earliest_datestamp.strftime("%Y-%m-%d"))
        identify << build("oai:deletedRecord",     deleted_record)
        identify << build("oai:granularity",       "YYYY-MM-DD")
      }

      repository << build("ListMetadataFormats") { |list_metadata_formats|

        list_metadata_formats << build("oai:metadataFormat") { |metadata_format|
          
           metadata_format << build("oai:metadataPrefix",    "oai_dc")
           metadata_format << build("oai:schema",            "http://www.openarchives.org/OAI/2.0/oai_dc.xsd")
           metadata_format << build("oai:metadataNamespace", "http://www.openarchives.org/OAI/2.0/oai_dc/")
        }
      }

      repository << build("ListRecords") { |list_records|

        list_records["metadataPrefix"] = "oai_dc"

        workflows.each do |workflow|

          list_records << build("oai:record") { |record|

            record << build("oai:header") { |header|

              header << build("oai:identifier", generate_workflow_id(workflow))
              header << build("oai:datestamp", workflow.created_at.strftime("%Y-%m-%d"))
            }

            record << build("oai:metadata") { |metadata|

              metadata << build("oai_dc:dc") { |dc|

                dc["xmlns:oai_dc"]       = "http://www.openarchives.org/OAI/2.0/oai_dc/" 
                dc["xmlns:dc"]           = "http://purl.org/dc/elements/1.1/" 
                dc["xmlns:xsi"]          = "http://www.w3.org/2001/XMLSchema-instance" 
                dc["xsi:schemaLocation"] = "http://www.openarchives.org/OAI/2.0/oai_dc/ " +
                                           "http://www.openarchives.org/OAI/2.0/oai_dc.xsd"

                dc << build("dc:title",       workflow.title)
                dc << build("dc:description", workflow.body)
                dc << build("dc:creator",     workflow.contributor.name)
                dc << build("dc:date",        workflow.created_at.strftime("%Y-%m-%d"))
              }
            }
          }
        end
      }
    }

    doc
  end
end
