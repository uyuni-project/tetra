# encoding: UTF-8

require "text"

# heuristically matches version strings
class VersionMatcher 
  
	# heuristically extracts a version string from a longer string (anything pseudo-numeric after a period
  # or a dash).
  # returns a [name, version] pair
	def self.split_version(full_name)	
    matches = full_name.match(/(.*?)(?:[\.\-\_ ~,]([0-9].*))?$/)
    if matches != nil and matches.length > 1
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
  def self.best_match(my_version, their_versions)
    $log.debug("version comparison: #{my_version} vs #{their_versions.join(', ')}")
  
    my_chunks = my_version.split /[\.\-\_ ~,]/
    their_chunks_hash = Hash[
      their_versions.map do |their_version|
        their_chunks_for_version = their_version.split /[\.\-\_ ~,]/
        their_chunks_for_version += [nil]*[my_chunks.length - their_chunks_for_version.length, 0].max
        [their_version, their_chunks_for_version]
      end
    ]
    
    max_chunks_length = ([my_chunks.length] + their_chunks_hash.values.map {|chunk| chunk.length}).max
    
    scoreboard = []
    their_versions.each do |their_version|
      their_chunks = their_chunks_hash[their_version]
      score = 0
      their_chunks.each_with_index do |their_chunk, i|
        score_multiplier = 100**(max_chunks_length -i -1)
        my_chunk = my_chunks[i]
        score += chunk_distance(my_chunk, their_chunk) * score_multiplier
      end
      scoreboard << {:version => their_version, :score => score}
    end
    
    scoreboard = scoreboard.sort_by {|element| element[:score]}

    $log.debug("scoreboard: ")
    scoreboard.each_with_index do |element, i|
      $log.debug("  #{i+1}. #{element[:version]} (score: #{element[:score]})")
    end
    
    winner = scoreboard.first
    
    if winner != nil
      return winner[:version]
    end
  end
  
  # returns a score representing the distance between two version chunks
  # for integers, the score is the difference between their values
  # for strings, the score is the Levenshtein distance
  # in any case score is normalized between 0 (identical) and 99 (very different/uncomparable)
  def self.chunk_distance(my_chunk, their_chunk)
    if my_chunk == nil
      my_chunk = "0"
    end
    if their_chunk == nil
      their_chunk = "0"
    end
    if my_chunk.is_i? and their_chunk.is_i?
      return [(my_chunk.to_i - their_chunk.to_i).abs, 99].min
    else
      return [Text::Levenshtein.distance(my_chunk.upcase, their_chunk.upcase), 99].min
    end
  end
end

class String
  def is_i?
    !!(self =~ /^[0-9]+$/)
  end
end

