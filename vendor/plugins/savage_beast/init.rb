#ActionView::Base.send :include, AuthenticatedSystem #SavageBeast::AuthenticationSystem
#ActionController::Base.send :include, AuthenticatedSystem

# Include your application configuration below
PASSWORD_SALT = '48e45be7d489cbb0ab582d26e2168621' unless Object.const_defined?(:PASSWORD_SALT)

Module.class_eval do
  def expiring_attr_reader(method_name, value)
    class_eval(<<-EOS, __FILE__, __LINE__)
      def #{method_name}
        class << self; attr_reader :#{method_name}; end
        @#{method_name} = eval(%(#{value}))
      end
    EOS
  end
end

class ActionView::Base
  def _(s)
    s
  end
end

#begin
#  require 'gettext/rails'
#  GetText.locale = "nl" # Change this to your preference language
#  #puts "GetText found!"
#rescue MissingSourceFile, LoadError
#  #puts "GetText not found.  Using English."
#  
#end