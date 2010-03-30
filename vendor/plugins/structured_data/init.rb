# myExperiment: vendor/plugins/structured_data/init.rb
#
# Copyright (c) 2009 University of Manchester and the University of Southampton.
# See license.txt for details.

ActiveRecord::Base.extend StructuredData::ActsMethods

AutoMigrate.migrate

