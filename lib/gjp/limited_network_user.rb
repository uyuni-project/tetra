# encoding: UTF-8

require 'find'

module Gjp
  # encapsulates a Linux user that cannot access the Internet
  # assumes root access (sudo) and iptables are available
  class LimitedNetworkUser
    def log
      Gjp.logger
    end

    def initialize(name)
      @name = name
    end

    # creates a new Linux user without Internet access,
    # if it does not exists
    def set_up
      log.debug "checking #{@name} user existence..."
      if not user_exists?
        log.debug "...not found. Setting up..."
        `sudo #{get_path("useradd")} #{@name}`
        `sudo #{get_path("passwd")} #{@name}`
        log.debug "...set up"
      end

      if not firewall_rule_exists?
        log.debug "...not found. Setting up..."
        `sudo #{get_path("iptables")} -A OUTPUT -m owner --uid-owner #{@name} -j DROP`
        log.debug "...set up"
      end
    end

    # deletes a Linux user previously created by this class
    def tear_down
      if firewall_rule_exists?
        `sudo #{get_path("iptables")} -D OUTPUT -m owner --uid-owner #{@name} -j DROP`
      end

      if user_exists?
        `sudo #{get_path("userdel")} #{@name}`
      end
    end

    # determines if a user without Internet access exists
    def set_up?
      user_exists? and firewall_rule_exists?
    end

    # checks user existence
    def user_exists?
      `id #{@name} 2>&1`.match(/no such user$/) == nil
    end

    # checks firewall rule existence
    def firewall_rule_exists?
      `sudo #{get_path("iptables")} -L`.match(/owner UID match #{@name}/) != nil
    end

    # returns a command's full path
    def get_path(command)
      `sudo which #{command}`.strip
    end
  end
end
