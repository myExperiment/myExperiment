# myExperiment: lib/biocatalog_import.rb
#
# Copyright (c) 2010 University of Manchester and the University of Southampton.
# See license.txt for details.

class BioCatalogueImport

  require 'xml/libxml'
  require 'open-uri'

  @@biocat_base_uri        = 'http://www.biocatalogue.org/'
  @@biocat_ns              = { "bc" => "http://www.biocatalogue.org/2009/xml/rest" }
  @@biocat_wait_in_seconds = 10

  def self.fetch_uri(uri)

    if @documents.nil?
      if File.exists?(@@biocat_document_cache)
        @documents = YAML::load_file(@@biocat_document_cache)
      else
        @documents = { :retrieved_at => { } }
      end
    end

    return @documents[uri] if @documents[uri]

    rest_uri = URI.parse(uri)
    rest_uri.path = rest_uri.path + ".xml"

    puts "Fetching URI: #{rest_uri}"

    @documents[uri] = open(rest_uri.to_s).read.to_s
    @documents[:retrieved_at][uri] = Time.now

    Kernel.sleep(@@biocat_wait_in_seconds)

    @documents[uri]
  end

  def self.uri_retrieved_at(uri)
    @documents[:retrieved_at][uri]
  end

  def self.save_document_cache
    file = File.open(@@biocat_document_cache, "w+") do |file|
      file.rewind
      file.puts(@documents.to_yaml)
    end
  end

  def self.get_text(element, query)
    response = element.find(query, @@biocat_ns)
    response[0].to_s unless response.length.zero?
  end

  def self.get_attr(element, query)
    response = element.find(query, @@biocat_ns)
    response[0].value unless response.length.zero?
  end

  def self.get_link(element, query)
    response = element.find(query, @@biocat_ns)
    (URI.parse(@@biocat_base_uri) + response[0].value).to_s unless response.length.zero?
  end

  def self.import_service(service_element, index_uri)

    summary_element = service_element.find('bc:summary', @@biocat_ns)[0]

    # Service

    service_uri = get_link(service_element, '@xlink:href')

#return service_uri unless service_uri.ends_with?("/2")
    service = Service.find_by_uri(service_uri)

    service = Service.new if service.nil?

    service.attributes = {

      :contributor              => @federation_source,

      :uri                      => service_uri,
      :name                     => get_text(service_element, 'bc:name/text()'),
      :submitter_label          => get_attr(service_element, 'bc:originalSubmitter/@resourceName'),
      :created                  => get_text(service_element, 'dcterms:created/text()'),
      :submitter_uri            => get_attr(service_element, 'bc:originalSubmitter/@xlink:href'),

      :provider_uri             => get_link(summary_element, 'bc:provider/@xlink:href'),
      :provider_label           => get_text(summary_element, 'bc:provider/bc:name/text()'),
      :endpoint                 => get_text(summary_element, 'bc:endpoint/text()'),
      :wsdl                     => get_text(summary_element, 'bc:wsdl/text()'),
      :city                     => get_text(summary_element, 'bc:location/bc:city/text()'),
      :country                  => get_text(summary_element, 'bc:location/bc:country/text()'),
      :iso3166_country_code     => get_text(summary_element, 'bc:location/bc:iso3166CountryCode/text()'),
      :flag_url                 => get_link(summary_element, 'bc:location/bc:flag/@xlink:href'),
      :documentation_uri        => get_text(summary_element, 'bc:documentationUrl/text()'),
      :description              => get_text(summary_element, 'dc:description/text()'),
      
      :monitor_label            => get_text(service_element, 'bc:latestMonitoringStatus/bc:label/text()'),
      :monitor_message          => get_text(service_element, 'bc:latestMonitoringStatus/bc:message/text()'),
      :monitor_symbol_url       => get_link(service_element, 'bc:latestMonitoringStatus/bc:symbol/@xlink:href'),
      :monitor_small_symbol_url => get_link(service_element, 'bc:latestMonitoringStatus/bc:smallSymbol/@xlink:href'),
      :monitor_last_checked     => get_text(service_element, 'bc:latestMonitoringStatus/bc:lastChecked/text()')
    }

    service.save if service.changed?

    if service.contribution.policy.nil?
      service.contribution = Contribution.create(:contributor => @federation_source)
      service.contribution.policy = create_default_policy(@federation_source)
      service.contribution.policy.share_mode = 0 # Make public
      service.contribution.policy.save
      service.contribution.save
    end

    # Service categories

    existing_service_categories = ServiceCategory.find_all_by_service_id(service.id)

    current_service_category_uris = []

    summary_element.find('bc:category', @@biocat_ns).each do |category_element|

      service_category_uri = get_link(category_element, '@xlink:href')

      service_category = ServiceCategory.find_by_service_id_and_uri(service.id, service_category_uri)

      service_category = ServiceCategory.new if service_category.nil?

      service_category.attributes = {
        :service       => service,
        :retrieved_at  => uri_retrieved_at(index_uri),
        :uri           => service_category_uri,
        :label         => get_text(category_element, 'text()')
      }

      service_category.save if service_category.changed?

      current_service_category_uris << service_category_uri
    end

    existing_service_categories.each do |service_category|
      next if current_service_category_uris.include?(service_category.uri)
      service_category.destroy
    end

    # Service technology types

    existing_service_types = ServiceType.find_all_by_service_id(service.id)

    current_types = []

    service_element.find('bc:serviceTechnologyTypes/bc:type', @@biocat_ns).each do |type_element|

      type_text = get_text(type_element, 'text()')

      service_type = ServiceType.find_by_service_id_and_label(service.id, type_text)

      service_type = ServiceType.new if service_type.nil?

      service_type.attributes = {
        :service       => service,
        :retrieved_at  => uri_retrieved_at(index_uri),
        :label         => type_text
      }

      service_type.save if service_type.changed?

      current_types << type_text
    end

    existing_service_types.each do |service_type|
      next if current_types.include?(service_type.label)
      service_type.destroy
    end

    # Service tags

    existing_service_tags = ServiceTag.find_all_by_service_id(service.id)

    current_service_tag_uris = []

    summary_element.find('bc:tag', @@biocat_ns).each do |tag_element|

      service_tag_uri   = get_link(tag_element, '@xlink:href')
      service_tag_label = get_text(tag_element, 'text()')

      service_tag = ServiceTag.find_by_service_id_and_uri(service.id, service_tag_uri)

      service_tag = ServiceTag.new if service_tag.nil?

      service_tag.attributes = {
        :service       => service,
        :retrieved_at  => uri_retrieved_at(index_uri),
        :uri           => service_tag_uri,
        :label         => service_tag_label
      }

      service_tag.save if service_tag.changed?

      current_service_tag_uris << service_tag_uri
    end

    existing_service_tags.each do |service_tag|
      next if current_service_tag_uris.include?(service_tag.uri)
      service_tag.destroy
    end

    # deployments and providers

    existing_service_providers = ServiceProvider.find(:all)
    existing_service_deployments = ServiceDeployment.find_all_by_service_id(service.id)

    current_service_deployments = []

    service_element.find('bc:deployments/bc:serviceDeployment', @@biocat_ns).each do |deployment_element|
      
      # provider

      provider_uri   = get_link(deployment_element, 'bc:serviceProvider/@xlink:href')
      deployment_uri = get_link(deployment_element, '@xlink:href')


      service_provider = ServiceProvider.find_by_uri(provider_uri)

      service_provider = ServiceProvider.new if service_provider.nil?

      service_provider.attributes = {
        :uri          => provider_uri,
        :retrieved_at => uri_retrieved_at(index_uri),
        :name         => get_text(deployment_element, 'bc:serviceProvider/bc:name/text()'),
        :description  => get_text(deployment_element, 'bc:serviceProvider/dc:description/text()'),
        :created      => get_text(deployment_element, 'bc:serviceProvider/dcterms:created/text()')
      }

      service_provider.save if service_provider.changed?

      # deployment

      service_deployment = ServiceDeployment.find_by_service_id_and_uri(service.id, deployment_uri)

      service_deployment = ServiceDeployment.new if service_deployment.nil?

      service_deployment.attributes = {
        :service              => service,
        :service_provider     => service_provider,
        :retrieved_at         => uri_retrieved_at(index_uri),
        :uri                  => get_link(deployment_element, '@xlink:href'),
        :endpoint             => get_text(deployment_element, 'bc:endpoint/text()'),
        :city                 => get_text(deployment_element, 'bc:location/bc:city/text()'),
        :country              => get_text(deployment_element, 'bc:location/bc:country/text()'),
        :iso3166_country_code => get_text(deployment_element, 'bc:location/bc:iso3166CountryCode/text()'),
        :flag_url             => get_link(deployment_element, 'bc:location/bc:flag/@xlink:href'),
        :submitter_label      => get_attr(deployment_element, 'bc:submitter/@resourceName'),
        :submitter_uri        => get_attr(deployment_element, 'bc:submitter/@xlink:href'),
        :created              => get_text(deployment_element, 'dcterms:created/text()')
      }

      service_deployment.save if service_deployment.changed?

      current_service_deployments << deployment_uri
    end

    existing_service_deployments.each do |service_deployment|
      next if current_service_deployments.include?(service_deployment.uri)
      service_deployment.destroy
    end

    # update the retrieved_at attribute

    ActiveRecord::Base.record_timestamps = false
    service.update_attribute(:retrieved_at, uri_retrieved_at(index_uri))
    ActiveRecord::Base.record_timestamps = true

    service_uri
  end

  def self.import_biocatalogue_services(uri)

    current_service_uris = []

    while true
      doc = LibXML::XML::Parser.string(fetch_uri(uri)).parse.root

      doc.find("/bc:services/bc:results/bc:service", @@biocat_ns).each do |service_element|
        current_service_uris << import_service(service_element, uri)
      end

      next_doc = doc.find("/bc:services/bc:related/bc:next/@xlink:href", @@biocat_ns)

      break if next_doc.length.zero?

      uri = next_doc[0].value
    end

    Service.find(:all).each do |service|

      next if current_service_uris.include?(service.uri)

      service.destroy
    end

    # destroy unused service providers

    current_service_providers = ServiceDeployment.find(:all).map do |sd| sd.service_provider end.uniq

    (ServiceProvider.find(:all) - current_service_providers).each do |service_provider|
      service_provider.destroy
    end

    save_document_cache
  end

  def self.import_biocatalogue

    if FederationSource.find_by_name("BioCatalogue").nil?
      FederationSource.create(:name => "BioCatalogue")
    end

    @@biocat_document_cache = ENV['FILE'] ? ENV['FILE'] : "tmp/biocatalogue.yml"

    @federation_source = FederationSource.find_by_name("BioCatalogue")

    import_biocatalogue_services("http://www.biocatalogue.org/services?include=summary,deployments&sort_order=asc")
  end
end

