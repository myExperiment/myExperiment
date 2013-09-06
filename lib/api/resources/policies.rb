# myExperiment: lib/api/resources/policies.rb
#
# Copyright (c) 2013 University of Manchester and the University of Southampton.
# See license.txt for details.

def get_policies(opts)
  policies = []

  if opts[:user].is_a?(User)
    if opts[:query]["type"] == 'group'
      policies = opts[:user].group_policies
    else
      policies = opts[:user].policies + opts[:user].group_policies
    end
  end

  produce_rest_list(opts[:uri], opts[:rules], opts[:query], policies, "policies", [], opts[:user])
end
