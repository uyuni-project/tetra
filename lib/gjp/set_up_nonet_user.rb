# encoding: UTF-8

module Gjp
  # implements the set-up-limited-nertwork-user subcommand
  class LimitedNetworkUserSetUp
    
    # sets up a user named "nonet"
    def self.set_up_nonet_user
      user = Gjp::LimitedNetworkUser.new("nonet")

      user.set_up

      "sudo #{user.get_path("useradd")} nonet\n" +
      "sudo #{user.get_path("iptables")} -A OUTPUT -m owner --uid-owner nonet -j DROP\n" +
      "User \"nonet\" set up, you can use \"sudo nonet\" to dry-run your build with no network access.\n" +
      "Note that the above iptables rule will be cleared at next reboot, you can use your distribution " +
      "tools to make it persistent or run \"gjp set-up-limited-nertwork-user\" again next time."
    end
  end
end