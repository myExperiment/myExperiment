class ComponentValidator

  VALIDATOR_PATH =
      "#{RAILS_ROOT}/vendor/java/component-validator/component-validator-0.0.1-SNAPSHOT-jar-with-dependencies.jar"

  def initialize(component, profile)
    @component_file = Tempfile.new('component')
    @component_file.write(component.content_blob.data)
    @component_file.close
    @profile_file = Tempfile.new('profile')
    @profile_file.write(profile.content_blob.data)
    @profile_file.close
  end

  def validate
    report = nil

    IO.popen("java -jar #{VALIDATOR_PATH} #{@component_file.path} #{@profile_file.path}", 'r+') do |validator|
      report = validator.read
    end

    parse_report(report)
  end

  private

  def parse_report(report)
    JSON.parse(report)
  end

end
