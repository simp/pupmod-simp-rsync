module Acceptance; end
module Acceptance::Helpers; end

module Acceptance::Helpers::Utils

  # @return Array of pairs of host indices that contains the position-invariant
  #   permutations of hosts in which the indices are unique
  #
  #   ['host1', 'host2'] returns [[0,1]]
  #   ['host1', 'host2', 'host3'] returns [[0,1], [0,2], [0,3], [1,2], [1,3], [2,3]]
  def unique_host_pairs(hosts)
    require 'set'
    unique_pairs = Set.new
    hosts.each_index do |index1|
      hosts.each_index do |index2|
        if index1 != index2
          unique_pairs.add([index1, index2].sort)
        end
      end
    end

    unique_pairs.to_a
  end
end
