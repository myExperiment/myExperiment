# Some gems use Array#nitems which isn't in Ruby 1.9 so I need this:

# From http://stackoverflow.com/a/8205275/509839

if ! Array.method_defined?(:nitems)
  class Array
    def nitems
      count{|x| !x.nil?}
    end
  end
end

