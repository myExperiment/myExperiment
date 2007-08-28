ActiveRecord::Base.send(:include, Jabberwock::SmartForm)
ActionView::Base.send(:include, Jabberwock::SmartForm::InstanceMethods)