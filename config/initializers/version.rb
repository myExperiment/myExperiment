module MyExperiment

  class Version

    def self.commit
      $commit ||= ENV['GIT_COMMIT'].presence || `git rev-parse HEAD`.presence || 'master'
    end

  end

end


