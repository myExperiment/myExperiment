#!/usr/bin/env ruby
require File.dirname(__FILE__) + '/config/environment'
# test methods are in /lib/policy_consistency_fixer.rb
require File.dirname(__FILE__) + '/lib/maintenance/policy_consistency_fixer'

include Maintenance

# Policy sanity checks and fixes (where necessary)

# NB! THIS SCRIPT WILL UPDATE THE STATE OF THE DATABASE,
# IF ANY INCONSISTENCIES ARE FOUND 
# (see inside of the checker script for details)

# run 'sanity_tests' and output the returned results string
check_and_fix_policies()
