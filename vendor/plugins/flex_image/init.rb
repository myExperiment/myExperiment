# Get RMagick
begin
  require 'RMagick'
rescue MissingSourceFile => e
  puts %{ERROR :: FlexImage requires the RMagick gem.  http://rmagick.rubyforge.org/install-faq.html}
  raise e
end

# Get dsl_accessor
begin
  require 'dsl_accessor'
rescue MissingSourceFile => e
  puts %{ERROR :: FlexImage requires the dsl_accessor gem.  "gem install dsl_accessor"}
  raise e
end

# Get FLexImage
require 'flex_image/controller'
require 'flex_image/model'
require 'flex_image/view'

# Assign template handlers
if ActionController::Base.respond_to?(:exempt_from_layout)
  ActionController::Base.exempt_from_layout :flexi
  ActionView::Base.register_template_handler :flexi, FlexImage::View
end