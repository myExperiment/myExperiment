# myExperiment: lib/workflow_types_handler.rb
#
# Copyright (c) 2008 University of Manchester and the University of Southampton.
# See license.txt for details.

# Helper class to deal with Workflow types and processors.
# Note that workflow types can exist that don't have corresponding processors.
class WorkflowTypesHandler
  
  # Gets all the workflow processor classes that have been defined in the \lib\workflow_processors directory.
  # Note: for performance reasons this is a "load once" method and thus requires a server restart if new processor classes are added.
  def self.processor_classes
    if @@processor_classes.nil?
      @@processor_classes = [ ]
      @@processor_display_names = { }
      @@processor_content_types = { }
      
      ObjectSpace.each_object(Class) do |c|
        if c < WorkflowProcessors::Interface
          @@processor_classes << c
          
          # Also populate the lookup tables for ease of use later.
          @@processor_display_names[c.display_name] = c
          @@processor_content_types[c.content_type] = c
          @@type_display_name_content_types[c.display_name] = c.content_type
        end
      end
    end
    
    return @@processor_classes
  end
  
  # Refreshes the list of all known workflow types in the system.
  # Note: this includes types that don't have corresponding processors (ie: custom types set in the db).
  def self.refresh_types!
    @@types = { }
    
    # First get the types defined by the processors found
    
    @@processor_display_names.each do |k,v|
      @@types[k] = v
    end
    
    # Then get the types stored in the database (removing duplicates)
    
    proc_c_types = @@processor_content_types.keys
    
    types_in_db = Workflow.find_by_sql("SELECT content_type FROM workflows GROUP BY content_type")
    
    types_in_db.each do |t|
      c_type = t[:content_type]
      @@types[c_type] = nil unless proc_c_types.include?(c_type) or @@types.has_key?(c_type)
    end
  end
  
  # Gets the list of known workflow types in the system, including ones that don't have corresponding processors.
  def self.types_list
    @@types.keys
  end
  
  # Attempts to find a matching processor class that can be used for the given workflow file/script.
  # Returns nil if no processor is found.
  def self.processor_class_for_file(file)
    proc_class = nil
    @@processor_classes.each do |c|
      proc_class = c if c.recognised?(file)
    end
    return proc_class
  end
  
  # Gets the corresponding content type for the workflow type's display name.
  # This either maps to a processor supported type, or otherwise (might be a type known in the db or a new type).
  # For the latter, the same type display name provided is returned as the content type.
  def content_type_for_type_display_name(type_display_name)
    if @@type_display_name_content_types.has_key(type_display_name)
      return @@type_display_name_content_types[type_display_name]
    else
      return type_display_name
    end
  end
  
protected

  # A catalogue of all the processor classes available.
  @@processor_classes = nil
  
  # The following should map the unique key values (which are based on what variable it is) with the corresponding processor class.
  # These act as quick lookup tables.
  @@processor_display_names = { }
  @@processor_content_types = { }
  
  # Map processor supported types (denoted by type display name) with corresponding content types.
  @@type_display_name_content_types = { }
  
  # Maps workflow types (denoted by type display name) with their corresponding processor classes 
  # (or nil if no processor exists for that type).
  # This is a more definitive collection of the types available in the system than the @@processor_display_name collection,
  # as it can include types that have been set in the database but which don't have any corresponding processors defined.
  @@types = { }

end

# We need to first retrieve all classes in the workflow_processors directory
# so that they are then accessible via the ObjectSpace.
# We assume (and this is a rails convention for anything in the /lib/ directory), 
# that filenames for example "my_class.rb" correspond to class names for example MyClass.
Dir.chdir(File.join(RAILS_ROOT, "lib/workflow_processors")) do
  Dir.glob("*.rb").each do |f|
    ("workflow_processors/" + f.gsub(/.rb/, '')).camelize.constantize
  end
end

# Load up the processor classes at startup
puts "Workflow type processors found: " + WorkflowTypesHandler.processor_classes.to_sentence

# Refresh the list of workflow types in the system
WorkflowTypesHandler.refresh_types!