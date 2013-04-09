# Ensure that module is namespaced with plugin name
module ForemanDiscovery
  module Host::ManagedExtensions
    extend ActiveSupport::Concern

    included do
      # execute standard callbacks
      after_validation :queue_reboot
    end

    def queue_reboot
      return unless type_changed? and ::Host::Base.find(self.id).type == "Host::Discovered"
      post_queue.create(:name => "Rebooting #{self}", :priority => 10000,
                        :action => [self, :setReboot])
    end

    def setReboot
      logger.info "ForemanDiscovery: Rebooting #{name} as its being discovered and assigned"
      if ::ProxyAPI::BMC.new(:url => "http://#{ip}:8443").power :action => "cycle"
        logger.info "ForemanDiscovery: reboot result: successful"
      else
        logger.info "ForemanDiscovery: reboot result: failed"
      end
    rescue => e
      failure "Failed to reboot: #{proxy_error e}"
    end

    def delReboot
      # nothing to do here, in reality we should never hit this method since this should be the
      # last action in the queue.
    end

  end
end