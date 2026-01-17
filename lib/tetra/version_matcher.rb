# frozen_string_literal: true

module Tetra
  # heuristically matches version strings
  class VersionMatcher
    include Logging

    # heuristically splits a full name into an artifact name and version string
    # assumes that version strings begin with a numeric character and are separated
    # by a ., -, _, ~ or space
    # returns a [name, version] pair
    def split_version(full_name)
      # 1. Match from the start (\A)
      # 2. Capture everything that is NOT a digit (ZERO or more times) -> *?
      # 3. Handle the optional separator
      # 4. Capture the version (MUST start with a digit)
      matches = full_name.match(/\A(?<name>[^0-9]*?)(?:[.\-_ ~,]?(?<version>[0-9].*))\z/)

      if matches
        [matches[:name], matches[:version]]
      else
        [full_name, nil]
      end
    end

    # returns the "best match" between a version number and a set of available version numbers
    # using a heuristic criterion.
    def best_match(my_version, their_versions)
      return nil if their_versions.nil? || their_versions.empty?

      log.debug("version comparison: #{my_version} vs #{their_versions.join(', ')}")

      my_chunks = my_version.split(Tetra::CHUNK_SEPARATOR_VERSION_MATCHER)

      # Use to_h (Ruby 2.6+) instead of Hash[]
      # Pre-calculate chunks for all versions to avoid re-splitting in the loop
      their_chunks_map = their_versions.to_h do |their_version|
        chunks = their_version ? their_version.split(Tetra::CHUNK_SEPARATOR_VERSION_MATCHER) : []

        # Pad with nil to match my_chunks length if shorter
        padding_needed = [my_chunks.length - chunks.length, 0].max
        chunks.fill(nil, chunks.length, padding_needed)

        [their_version, chunks]
      end

      # Calculate max length across all candidates (including myself)
      max_chunks_length = ([my_chunks.length] + their_chunks_map.values.map(&:length)).max

      # Calculate scores
      scoreboard = their_versions.map do |their_version|
        their_chunks = their_chunks_map[their_version]
        score = 0

        their_chunks.each_with_index do |their_chunk, i|
          # Weighting: Earlier chunks are vastly more important
          score_multiplier = 100**(max_chunks_length - i - 1)
          my_chunk = my_chunks[i]

          score += chunk_distance(my_chunk, their_chunk) * score_multiplier
        end

        { version: their_version, score: score }
      end

      # Sort by lowest score (best match)
      sorted_scoreboard = scoreboard.sort_by { |entry| entry[:score] }

      log.debug("scoreboard: ")
      sorted_scoreboard.each_with_index do |entry, i|
        log.debug("  #{i + 1}. #{entry[:version]} (score: #{entry[:score]})")
      end

      sorted_scoreboard.first[:version]
    end

    # returns a score representing the distance between two version chunks
    # for integers, the score is the difference between their values
    # for strings, the score is the Levenshtein distance
    # in any case score is normalized between 0 (identical) and 99 (very different/uncomparable)
    def chunk_distance(my_chunk, their_chunk)
      # Normalize nils to "0"
      my_chunk ||= "0"
      their_chunk ||= "0"

      # If exact match, distance is 0
      return 0 if my_chunk == their_chunk

      if integer?(my_chunk) && integer?(their_chunk)
        diff = (my_chunk.to_i - their_chunk.to_i).abs
        [diff, 99].min
      else
        dist = Text::Levenshtein.distance(my_chunk.upcase, their_chunk.upcase)
        [dist, 99].min
      end
    end

    private

    # true for integer strings
    def integer?(string)
      # Faster than regex for simple digit checks
      Integer(string, 10)
      true
    rescue ArgumentError, TypeError
      false
    end
  end
end
