module DeprecatedMethodsHelper
#TODO: Inline me?
  def error_messages_for(obj)
    object = instance_variable_get("@#{obj}")

    if object.errors.any?
      content_tag(:div, :id => 'errorExplanation') do
        content_tag(:h2, "#{pluralize(object.errors.count, "error")} prohibited this user from being saved:") +
        content_tag(:ul) do
          object.errors.full_messages.map do |msg|
            concat(content_tag(:li, msg))
          end
        end
      end
    end
  end
end