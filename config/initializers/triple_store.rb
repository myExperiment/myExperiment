# myExperiment: config/initializers/triple_store.rb
#
# Copyright (c) 2013 University of Manchester and the University of Southampton.
# See license.txt for details.

require 'sesame'

class TripleStore

  if Rails.env == 'test'
    @instance = DummyTripleStore::Repository.new
  elsif Conf.enable_triple_store
    @instance = Sesame::Repository.new(Conf.sesame_repository, 'myexp_sesame')
  end

  def self.instance
    @instance
  end
end
