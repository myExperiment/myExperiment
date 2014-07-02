module DeprecatedMethodsHelper
#TODO: Inline me?
  def error_messages_for(obj)
    object = eval("@#{obj.to_s}")

    if object.errors.any?
      content_tag(:ul) do
        @post.errors.full_messages.each do |msg|
          content_tag(:li) do
            msg
          end
        end
      end
    end
  end
end