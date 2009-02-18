ActiveRecord::Base.class_eval do
  include ActionView::Helpers::TagHelper, ActionView::Helpers::TextHelper, WhiteListHelper
  def self.format_attribute(attr_name)
    class << self; include ActionView::Helpers::TagHelper, ActionView::Helpers::TextHelper, WhiteListHelper; end
    define_method(:body)       { read_attribute attr_name }
    define_method(:body_html)  { read_attribute "#{attr_name}_html" }
    define_method(:body_html=) { |value| write_attribute "#{attr_name}_html", value }
    before_save :format_content
  end

  def dom_id
    [self.class.name.downcase.pluralize.dasherize, id] * '-'
  end

  protected

  def render_plain_text_to_html(text)

    # separate paragraphs that end with a colon

    text.gsub!(/:\n/, ":\n\n")
    
    # fold indented parts of bulleted lines

    text.gsub!(/^\* .*\n(  .*\n)+/) { |b|
      b.gsub(/\n/, " ") + "\n"
    }

    # fold indented parts of numbered lines

    text.gsub!(/^[0-9]+\. .*\n(   .*\n)+/) { |b|
      b.gsub(/\n/, " ") + "\n"
    }

    # convert each adjacent set of bulleted lines into HTML

    text.gsub!(/^\* .*\n(\* .*\n|\s*\n)*/) { |b|
      b.gsub!(/^\s*\n/, "")
      "\n<ul>\n" + b.gsub(/^\* (.*)/, '<li>\1</li>') + "</ul>\n\n"
    }

    # convert each adjacent set of numbered lines into HTML

    text.gsub!(/^[0-9]+\. .*\n(([0-9]+\. .*\n)|\s*\n)*/) { |b|
      b.gsub!(/^\s*\n/, "")
      "\n<ol>\n" + b.gsub(/^([0-9]+)\. (.*)/, '<li value="\1">\2</li>') + "</ol>\n\n"
    }

    # make sure the last line is terminated

    text = "#{text}\n"

    # fold multiple adjacent blank lines

    text.gsub!(/^\s*\n(\s*\n)*/, "\n")

    # place each section in an HTML paragraph

    text.gsub!(/((^.*\S+.*\n)+)/, "<p>\n\\1</p>\n")

    text
  end


    def format_content
      body.strip! if body.respond_to?(:strip!)
      self.body_html = body.blank? ? '' : body_html_with_formatting
    end
    
    def body_html_with_formatting
      body_html = auto_link(body.starts_with?('<') ? body : render_plain_text_to_html(body))
      white_list(body_html)
    end
end
