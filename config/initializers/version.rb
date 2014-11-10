module MyExperiment

  class Version

    def self.commit
      $commit ||= `git log -n 1`.split("\n")[0].split[1]
    end

  end

end


