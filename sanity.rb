#!/usr/bin/env ruby
require File.dirname(__FILE__) + '/config/environment'

# Sanity checks

@results = [ ]

def process_result(msg, success)
  printf("%-70s: %s\n", msg, success ? "Success" : "Failed")
  @results.push(success)
end

def should_be_empty(msg, list)
  process_result(msg, list.empty?)
end

def should_be_true(msg, state)
  process_result(msg, state == true)
end

def should_all_be_true(msg, states)
  process_result(msg, (states - [true]).empty?)
end

def list_items_are_distinct(ax)
  ax.length == ax.uniq.length
end

def should_have_one_to_one_mapping(a_str, b_str, a, b)

  a_extra = a - b
  b_extra = b - a

  result = process_result("1:1 mapping between #{a_str.pluralize} and #{b_str.pluralize}",
      a_extra.length == 0 && b_extra.length == 0)

  a_extra.each do |item|
    puts "Extra #{a_str}: #{item.inspect}"
  end

  b_extra.each do |item|
    puts "Extra #{b_str}: #{item.inspect}"
  end

  result
end

def test
  users         = User.find(:all)
  workflows     = Workflow.find(:all)
  blogs         = Blog.find(:all)
  blobs         = Blob.find(:all)
  forums        = Forum.find(:all)
  contributions = Contribution.find(:all)

  known_contributables = workflows + blobs + blogs + forums

  should_be_empty("All users must have a name",
      users.select do |u| u.name == nil or u.name.length == 0 end)

  should_be_empty("All users with a username must have a password",
      users.select do |u| u.username.nil? != u.crypted_password.nil? end)

  # contributions

  should_be_empty("All workflows must have a contribution record",
      workflows.select do |w| w.contribution.nil? end)

  should_be_empty("All files must have a contribution record",
      blobs.select do |b| b.contribution.nil? end)

  should_be_empty("All blogs must have a contribution record",
      blogs.select do |b| b.contribution.nil? end)

  should_be_empty("All forums must have a contribution record",
      forums.select do |f| f.contribution.nil? end)

  should_be_true("All contributables should have distinct contribution records",
      list_items_are_distinct(known_contributables.map do |c| c.contribution end))

  should_have_one_to_one_mapping('known contributable', 'contribution record',
      known_contributables.map do |c| c.contribution end, contributions)

  # workflows

  should_all_be_true("All workflow image files must exist",
      workflows.map do |w| File.exists?(w.image) end)

  should_all_be_true("All workflow svg files must exist",
      workflows.map do |w| File.exists?(w.svg) end)

  should_be_empty("All workflows must have a content type",
      workflows.select do |w| w.content_type.length.zero? end)

end

test

puts ""
puts "Total tests:      #{@results.length}"
puts "Successful tests: #{@results.select do |r| r == true end.length}"
puts "Failed tests:     #{@results.select do |r| r == false end.length}"
puts ""

