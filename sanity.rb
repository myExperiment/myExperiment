#!/usr/bin/env ruby
require File.dirname(__FILE__) + '/config/environment'
# test methods are in /lib/sanity_test.rb
require File.dirname(__FILE__) + '/lib/sanity_test'

# Sanity checks

# run 'sanity_tests' and output the returned results string
puts sanity_tests

