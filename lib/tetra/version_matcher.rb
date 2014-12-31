# encoding: UTF-8

module Tetra
  # heuristically matches version strings
  class VersionMatcher
    include Logging

    # heuristically splits a full name into an artifact name and version string
    # assumes that version strings begin with a numeric character and are separated
    # by a ., -, _, ~ or space
    # returns a [name, version] pair
    def split_version(full_name)
      matches = full_name.match(/(.*?)(?:[\.\-\_ ~,]?([0-9].*))?$/)
      if !matches.nil? && matches.length > 1
        [matches[1], matches[2]]
      else
        [full_string, nil]
      end
    end

    # returns the "best match" between a version number and a set of available version numbers
    # using a heuristic criterion. Idea:
    #  - split the version number in chunks divided by ., - etc.
    #  - every chunk with same index is "compared", differences make up a score
    #  - "comparison" is a subtraction if the chunk is an integer, a string distance measure otherwise
    #  - score weighs differently on chunk index (first chunks are most important)
    #  - lowest score wins
    def best_match(my_version, their_versions)
      log.debug("version comparison: #{my_version} vs #{their_versions.join(', ')}")

      my_chunks = my_version.split(/[\.\-\_ ~,]/)
      their_chunks_hash = Hash[
                          their_versions.map do |their_version|
                            their_chunks_for_version = (
                              if !their_version.nil?
                                their_version.split(/[\.\-\_ ~,]/)
                              else
                                []
                              end
                            )
                            chunks_count = [my_chunks.length - their_chunks_for_version.length, 0].max
                            their_chunks_for_version += [nil] * chunks_count
                            [their_version, their_chunks_for_version]
                          end
      ]

      max_chunks_length = ([my_chunks.length] + their_chunks_hash.values.map(&:length)).max

      scoreboard = []
      their_versions.each do |their_version|
        their_chunks = their_chunks_hash[their_version]
        score = 0
        their_chunks.each_with_index do |their_chunk, i|
          score_multiplier = 100**(max_chunks_length - i - 1)
          my_chunk = my_chunks[i]
          score += chunk_distance(my_chunk, their_chunk) * score_multiplier
        end
        scoreboard << { version: their_version, score: score }
      end

      scoreboard = scoreboard.sort_by { |element| element[:score] }

      log.debug("scoreboard: ")
      scoreboard.each_with_index do |element, i|
        log.debug("  #{i + 1}. #{element[:version]} (score: #{element[:score]})")
      end

      return scoreboard.first[:version] unless scoreboard.first.nil?
    end

    # returns a score representing the distance between two version chunks
    # for integers, the score is the difference between their values
    # for strings, the score is the Levenshtein distance
    # in any case score is normalized between 0 (identical) and 99 (very different/uncomparable)
    def chunk_distance(my_chunk, their_chunk)
      my_chunk = "0" if my_chunk.nil?
      their_chunk = "0" if their_chunk.nil?

      if i?(my_chunk) && i?(their_chunk)
        return [(my_chunk.to_i - their_chunk.to_i).abs, 99].min
      else
        return [Text::Levenshtein.distance(my_chunk.upcase, their_chunk.upcase), 99].min
      end
    end

    # true for integer strings
    def i?(string)
      string =~ /^[0-9]+$/
    end
  end
end
