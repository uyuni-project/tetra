# frozen_string_literal: true

module Tetra
  # encapsulates tetra-specific Gradle commandline options
  class Gradle
    # returns a command line for running Gradle
    def self.commandline(project_path)
      gradle_user_home = File.join(project_path, "kit", "gradle-home")
      gradle_bin = File.join(project_path, "gradlew")

      "#{gradle_bin} --gradle-user-home=#{gradle_user_home}"
    end
  end
end
