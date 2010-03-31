# myExperiment: lib/biocatalog_import.rb
#
# Copyright (c) 2010 University of Manchester and the University of Southampton.
# See license.txt for details.

class BioCatalogueImport

  require 'xml/libxml'

  @@biocat_base_uri        = 'http://www.biocatalogue.org/'
  @@biocat_ns              = { "bc" => "http://www.biocatalogue.org/2009/xml/rest" }
  @@biocat_document_cache  = "tmp/biocatalogue.yml"
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

    @documents[uri] = rest_uri.read.to_s
    @documents[:retrieved_at][uri] = Time.now

    puts "Got it."
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

  def self.import_service(service_uri)

    service_element = LibXML::XML::Parser.string(fetch_uri(service_uri)).parse.root

    summary_uri     = get_attr(service_element, '/bc:service/bc:related/bc:summary/@xlink:href')
    deployment_uri  = get_attr(service_element, '/bc:service/bc:related/bc:deployments/@xlink:href')
    variants_uri    = get_attr(service_element, '/bc:service/bc:related/bc:variants/@xlink:href')
    annotations_uri = get_attr(service_element, '/bc:service/bc:related/bc:annotations/@xlink:href')
    monitoring_uri  = get_attr(service_element, '/bc:service/bc:related/bc:monitoring/@xlink:href')

    summary_element     = LibXML::XML::Parser.string(fetch_uri(summary_uri)).parse.root
    deployments_element = LibXML::XML::Parser.string(fetch_uri(deployment_uri)).parse.root
    variants_element    = LibXML::XML::Parser.string(fetch_uri(variants_uri)).parse.root
    annotations_element = LibXML::XML::Parser.string(fetch_uri(annotations_uri)).parse.root
    monitoring_element  = LibXML::XML::Parser.string(fetch_uri(monitoring_uri)).parse.root

    service = Service.create(
        :retrieved_at       => uri_retrieved_at(service_uri),

        :contributor        => @federation_source,

        :uri                => get_link(service_element, '/bc:service/@xlink:href'),
        :name               => get_text(service_element, '/bc:service/bc:name/text()'),
        :submitter_label    => get_attr(service_element, '/bc:service/bc:originalSubmitter/@resourceName'),
        :created            => get_text(service_element, '/bc:service/dcterms:created/text()'),
        :submitter_uri      => get_attr(service_element, '/bc:service/bc:originalSubmitter/@xlink:href'),

        :provider_uri         => get_link(summary_element, '/bc:service/bc:summary/bc:provider/@xlink:href'),
        :provider_label       => get_text(summary_element, '/bc:service/bc:summary/bc:provider/bc:name/text()'),
        :endpoint             => get_text(summary_element, '/bc:service/bc:summary/bc:endpoint/text()'),
        :wsdl                 => get_text(summary_element, '/bc:service/bc:summary/bc:wsdl/text()'),
        :city                 => get_text(summary_element, '/bc:service/bc:summary/bc:location/bc:city/text()'),
        :country              => get_text(summary_element, '/bc:service/bc:summary/bc:location/bc:country/text()'),
        :iso3166_country_code => get_text(summary_element, '/bc:service/bc:summary/bc:location/bc:iso3166CountryCode/text()'),
        :flag_url             => get_link(summary_element, '/bc:service/bc:summary/bc:location/bc:flag/@xlink:href'),
        :documentation_uri    => get_text(summary_element, '/bc:service/bc:summary/bc:documentationUrl/text()'),
        :description          => get_text(summary_element, '/bc:service/bc:summary/dc:description/text()'),
        
        :monitor_label            => get_text(summary_element, '/bc:service/bc:latestMonitoringStatus/bc:label/text()'),
        :monitor_message          => get_text(summary_element, '/bc:service/bc:latestMonitoringStatus/bc:message/text()'),
        :monitor_symbol_url       => get_link(summary_element, '/bc:service/bc:latestMonitoringStatus/bc:symbol/@xlink:href'),
        :monitor_small_symbol_url => get_link(summary_element, '/bc:service/bc:latestMonitoringStatus/bc:smallSymbol/@xlink:href'),
        :monitor_last_checked     => get_text(summary_element, '/bc:service/bc:latestMonitoringStatus/bc:lastChecked/text()'))

    service.contribution.policy = create_default_policy(@federation_source)
    service.contribution.policy.share_mode = 0 # Make public
    service.contribution.policy.save
    service.contribution.save

    summary_element.find('/bc:service/bc:summary/bc:category', @@biocat_ns).each do |category_element|
      ServiceCategory.create(
          :service       => service,
          :retrieved_at  => uri_retrieved_at(summary_uri),
          :uri           => get_link(category_element, '@xlink:href'),
          :label         => get_text(category_element, 'text()'))
    end

    summary_element.find('/bc:service/bc:summary/bc:serviceType', @@biocat_ns).each do |category_element|
      ServiceType.create(
          :service      => service,
          :retrieved_at => uri_retrieved_at(summary_uri),
          :label        => get_text(category_element, 'text()'))
    end

    summary_element.find('/bc:service/bc:summary/bc:tag', @@biocat_ns).each do |tag_element|
      ServiceTag.create(
          :service      => service,
          :retrieved_at => uri_retrieved_at(summary_uri),
          :uri          => get_link(tag_element, '@xlink:href'),
          :label        => get_text(tag_element, 'text()'))
    end

    # deployments and providers

    service_element.find('/bc:service/bc:deployments/bc:serviceDeployment', @@biocat_ns).each do |deployment_element|
      
      deployment_uri = get_link(deployment_element, '@xlink:href')
      provider_uri   = get_link(deployment_element, 'bc:serviceProvider/@xlink:href')

      next if ServiceDeployment.find_by_uri(deployment_uri)

      if ServiceProvider.find_by_uri(provider_uri).nil?
        ServiceProvider.create(
            :uri          => provider_uri,
            :retrieved_at => uri_retrieved_at(service_uri),
            :name         => get_text(deployment_element, 'bc:serviceProvider/bc:name/text()'),
            :description  => get_text(deployment_element, 'bc:serviceProvider/dc:description/text()'),
            :created      => get_text(deployment_element, 'bc:serviceProvider/dcterms:created/text()'))
      end

      provider = ServiceProvider.find_by_uri(provider_uri)

      deployment = ServiceDeployment.create(
          :service              => service,
          :service_provider     => provider,
          :retrieved_at         => uri_retrieved_at(service_uri),
          :uri                  => get_link(deployment_element, '@xlink:href'),
          :endpoint             => get_text(deployment_element, 'bc:endpoint/text()'),
          :city                 => get_text(deployment_element, 'bc:location/bc:city/text()'),
          :country              => get_text(deployment_element, 'bc:location/bc:country/text()'),
          :iso3166_country_code => get_text(deployment_element, 'bc:location/bc:iso3166CountryCode/text()'),
          :flag_url             => get_link(deployment_element, 'bc:location/bc:flag/@xlink:href'),
          :submitter_label      => get_attr(deployment_element, 'bc:submitter/@resourceName'),
          :submitter_uri        => get_attr(deployment_element, 'bc:submitter/@xlink:href'),
          :created              => get_text(deployment_element, 'dcterms:created/text()'))

    end
  end

  def self.import_biocatalogue_services(uri)

    while true

      doc = LibXML::XML::Parser.string(fetch_uri(uri)).parse.root

      doc.find("/bc:services/bc:results/bc:service", @@biocat_ns).each do |service_element|
        import_service(get_link(service_element, '@xlink:href'))
      end

      next_doc = doc.find("/bc:services/bc:related/bc:next/@xlink:href", @@biocat_ns)

      break if next_doc.length.zero?

      uri = next_doc[0].value
    end

    save_document_cache

  end

  def self.import_biocatalogue

    if FederationSource.find_by_name("BioCatalogue").nil?
      FederationSource.create(:name => "BioCatalogue")
    end

    @federation_source = FederationSource.find_by_name("BioCatalogue")

    import_biocatalogue_services("http://www.biocatalogue.org/services")
  end
end

