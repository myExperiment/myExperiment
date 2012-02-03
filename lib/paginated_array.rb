# myExperiment: lib/paginated_array.rb
#
# Copyright (c) 2009 University of Manchester and the University of Southampton.
# See license.txt for details.

class PaginatedArray < Array

  def initialize(collection, args = {})

    collection.each do |item| self << item end

    @total  = args[:total]
    @limit  = args[:limit]
    @offset = args[:offset]
  end

  def page_count
    return 1 if @total == 0
    ((@total - 1) / @limit) + 1
  end

  def first_page
    1
  end

  def last_page
    page_count
  end

  def previous_page?
    page != first_page
  end

  def previous_page
    page - 1
  end

  def next_page?
    page != last_page
  end

  def next_page
    page + 1
  end

  def page
    (@offset / @limit) + 1
  end

  def page_exists?(x)
    return false if x < first_page
    return false if x > last_page

    true
  end
end

