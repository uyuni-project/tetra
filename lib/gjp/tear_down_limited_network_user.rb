# encoding: UTF-8

module Gjp
  # implements the tear-down-limited-nertwork-user subcommand
  class LimitedNetworkUserTearDown
    
    # deletes a user named "nonet"
    def self.tear_down_limited_nertwork_user
      user = Gjp::LimitedNetworkUser.new("nonet")

      user.tear_down

      "sudo #{user.get_path("iptables")} -D OUTPUT -m owner --uid-owner nonet -j DROP\n" +
      "sudo #{user.get_path("userdel")} nonet\n"
    end
  end
end