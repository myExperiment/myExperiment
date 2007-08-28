# Contains modules related to SmartForm
module Jabberwock # :nodoc:
  # raised when a column is not found
  class ColumnNotFound < ActiveRecord::ActiveRecordError; end
  # raised when an unknown column type is discovered; should hopefully never be raised
  class UnknownColumnType < StandardError; end 
  
  # ActionView helper methods with intelligence!
  #
  # ==Generators:
  #   * +SmartFormStyles+ - +ruby ./script/generate SmartFormStyles+
  #
  # You can generate a sample style-sheet with ruby ./script/generate SmartFormStyle
  #
  # Author:: Jabberwock (jabberwock /AT tenebrous /DOT com)
  # Copyright:: Copyright(c) 2007 Jabbewock 
  # License:: BSD 
  # Request:: Please feel free to e-mail me with feedback!
  module SmartForm
    $sf_author = "jabberwock /AT tenebrous /DOT com, or Jabberwock on irc.freenode.net"

    unless defined?(DEFAULT_FORM_OPTIONS)=="constant"
      # Default option values:
      DEFAULT_FORM_OPTIONS = {
        :object               => nil,
        :exclude              => ['created_at','updated_at'],
        :include              => [],
        :habtm_select_values  => {},
        :class                => "smart_form",
        :style                => "",
        :id                   => "",
        :text_field           => { :size => 25 },
        :number_text_field    => { :size => 5 },
        :text_area            => { :cols => 40, :rows => 5 },
        :select               => { :include_blank => true, :html => {} },
        :date_select          => {},
        :datetime_select      => {},
        :time_select          => {},
        :mselect              => { :size => 10 },
        :mselect_footnote     => "(crtl+click to select multiple)",
        :left_width           => 0,
        :right_width          => 0
      }
    end

    # "included" is automatically called any time a Module is included into a class.
    # The 'base' argument the class that is including the module. I'm documenting this
    # because no one else seems to :)
    def self.included(base)
      base.extend(ClassMethods)
    end
  end # SmartForm
end # Jabberwock

