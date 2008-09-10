# myExperiment: lib/sanity_test.rb
# 
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

# contains all methods needed to run sanity tests
# used by StatusController and sanity.rb

def process_result(msg, success)
  @results_string += "%-70s" % msg 
  @results_string += ": " + (success ? "Success" : "Failed") + "\n"
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
    @results_string += "Extra #{a_str}: #{item.inspect}\n"
  end

  b_extra.each do |item|
    @results_string += "Extra #{b_str}: #{item.inspect}\n"
  end

  result
end

def sanity_tests

  @results = [ ]
  @results_string = ""

  users         = User.find(:all)
  workflows     = Workflow.find(:all)
  blogs         = Blog.find(:all)
  blobs         = Blob.find(:all)
  forums        = Forum.find(:all)
  packs         = Pack.find(:all)
  contributions = Contribution.find(:all)

  known_contributables = workflows + blobs + blogs + forums + packs

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

  should_be_empty("All packs must have a contribution record",
      packs.select do |f| f.contribution.nil? end)

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

  @results_string += "\nTotal tests:      #{@results.length}\n"
  @results_string += "Successful tests: #{@results.select do |r| r == true end.length}\n"
  @results_string += "Failed tests:     #{@results.select do |r| r == false end.length}\n\n"

  @results_string
end

