# Modified from: http://forums.pragprog.com/forums/8/topics/2

module WriteOnceOf
  def validates_write_once_of(*attr_names)
    configuration = { :message => "can't be changed" }
    configuration.merge!(attr_names.pop) if attr_names.last.is_a?(Hash)
    send( validation_method(:update) ) do |record|
      unless configuration[:if] and not evaluate_condition(configuration[:if], record)
        previous = self.find record.id
        attr_names.each do |attr_name|
          # Updated from original [Jits, 2008-01-09]: added condition below, to allow attributes to be set at a later stage.
          # So write once check is only done if the old value was not nil.
          unless eval("previous.#{attr_name}.nil?")
            record.errors.add( attr_name, configuration[:message] ) if record.respond_to?(attr_name) and previous.send(attr_name) != record.send(attr_name)
            # replace the 'and' above with a double ampersand
          end
        end
      end
    end
  end
end

ActiveRecord::Base.extend WriteOnceOf