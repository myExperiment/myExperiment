module DeprecatedMethodsHelper
#TODO: Inline me?
  def error_messages_for(obj)
    object = instance_variable_get("@#{obj}")

    if object.errors.any?
      content_tag(:ul) do
        object.errors.full_messages.each do |msg|
          content_tag(:li) do
            msg
          end
        end
      end
    end
  end
end