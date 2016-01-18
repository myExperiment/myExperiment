# myExperiment: config/initializers/datacite_client.rb
#
# Copyright (c) 2015 University of Manchester and the University of Southampton.
# See license.txt for details.

class DataciteClient

  if Rails.env == 'test'
    @instance = DummyDataciteClient.new
  elsif Conf.datacite_enabled?
    @instance = Datacite.new(Conf.datacite_username, Base64.decode64(Conf.datacite_password).chomp, Conf.datacite_url)
  end

  def self.instance
    @instance
  end
end
