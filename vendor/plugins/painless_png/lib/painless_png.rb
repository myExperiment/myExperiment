# Painless PNG fix for Internet Explorer 6
#
# If you fancy beautiful drop shadows, reflections and anti-aliasing in your website
# images then you'll probably find that PNG is perfectly suited to display all
# these effects.
#
# What's more, PNG is now supported Internet Explorer 7, Mozilla Firefox, Safari,
# Opera and practically every modern browser.
#
# That's the good news.
#
# The bad news is that Internet Explorer 6 doesn't support alpha transparency in PNG
# images, which means that any pixels with transparency will be fully opaque.
#
# Many fixes have been suggested, one more painful than the other.
#
# This fix is done the Rails way. It's a simple plugin that uses Microsoft's
# recommended way of handling PNGs. And the beauty is it's fully transparent
# to the programmer -- you can keep using image_tag. What's more, it integrates
# seamlessly with your existing application -- you can keep all your existing
# image_tags
#
# Known limitations:
#    * Won't work when browsers cloak themselves as Internet Explorer versions 5.5 - 6.x.
#    * Doesn't work with PNGs in CSS files
#

module ActionView::Helpers::AssetTagHelper

  # Lightning fast way to read PNG size (only loads the necessary parts from the file)
  # Brilliant stuff found on http://snippets.dzone.com/posts/show/805
  def get_png_size(filename)
    IO.read(filename)[0x10..0x18].unpack('NN')
  end

  # Determines whether this is Internet Explorer version 5.5-6.x
  def legacy_browser?
    request.user_agent =~ /MSIE\s+(5\.5|6\.)/
  end
  
  alias_method :image_tag_old, :image_tag

  def image_tag(source, options={})
    # Use the vanilla image tag if this isn't a PNG
    #
    # We need to be careful because Rails automatically adds the .png extension
    # when no extension is given. Although this feature is now deprecated we still
    # need to cater for it.
    #
    # This we do by piping the source through rails' image_path method, which
    # automatically adds this extension for us where needed.
    return image_tag_old(source, options) if not image_path(source) =~ /\.png(\?\d+)?$/i
    
    # For non-legacy browsers we use the vanilla image tag
    return image_tag_old(source, options) if not legacy_browser?
  
    # Setup shamelessly stolen from the image_tag source
    options.symbolize_keys!
    if options[:size]
      options[:width], options[:height] = options[:size].split("x") if options[:size] =~ %r{^\d+x\d+$}
      options.delete(:size)
    end
  
    styles = {}
  
    # For this hack to work we must set the width and height of the div explicitly. If
    # the user didn't override the dimensions then we set them directly from the image
    # file.
    #
    # Also: remove the trailing numbers that rails suffixes to the image names
    # TODO: find out what these numbers are (I think it's to do with caching?)
    #
    # Note that we use the original image_tag method to determine the file path
    # rather than image_tag, since image_tag doesn't work with engines (it won't
    # accept an options argument).
    asset_path = image_tag_old(source, options).gsub(/^.*src=\"([^"]*\.png)(\?\d+)?\".*$/, '\1')
    image_file = "#{RAILS_ROOT}/public#{asset_path}"
    styles[:width], styles[:height] = get_png_size(image_file)
    styles[:width] = "#{styles[:width]}px"
    styles[:height] = "#{styles[:height]}px"

    # Override user dimensions if given
    styles[:width] = options[:width] if options[:width]
    styles[:height] = options[:height] if options[:height]
  
    # This is the cornerstone of the hack: apply the propriety alpha transform filter
    styles[:filter] = "progid:DXImageTransform.Microsoft.AlphaImageLoader(src='#{asset_path}', sizingMethod='scale')"

    styles_string = styles.map { |key, value| %(#{key}:#{value}) }.join(";")
    options[:style] = styles_string + (options[:style] ? "; #{options[:style]}" : "")
  
    # Place the filter in a div
    content_tag('div', nil, options) 
  end

end


# Monkey patch the test environment
#if RAILS_ENV == "test"
  module ActionController
    class TestRequest < AbstractRequest
      attr_accessor :user_agent
    end
  end
#end
