#!/usr/bin/env ruby
require File.dirname(__FILE__) + '/config/environment'
# test methods are in /lib/sanity_test.rb
require File.dirname(__FILE__) + '/lib/sanity_test'

# Sanity checks

# include SanityTest
puts sanity_tests

#puts ""
#puts "Total tests:      #{@results.length}"
#puts "Successful tests: #{@results.select do |r| r == true end.length}"
#puts "Failed tests:     #{@results.select do |r| r == false end.length}"
#puts ""

