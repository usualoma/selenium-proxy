require 'optparse'

module SeleniumProxyStartServer
  class CLI
    def self.execute(stdout, arguments=[], &block)

      options = { }
      mandatory_options = %w(  )

      parser = OptionParser.new do |opts|
        opts.banner = <<-BANNER.gsub(/^          /,'')
          Usage: #{File.basename($0)} [options]

          Options are:
        BANNER
        opts.separator ""
        opts.on("-d", "--drb-uri URI", String,
                "URI passed to DRb.start_service",
                "Default: " + SeleniumProxy::Server.default_drb_uri
               ) { |arg| options[:drb_uri] = arg }
        opts.on("-h", "--help",
                "Show this help message.") { stdout.puts opts; exit }
        opts.parse!(arguments)

        if mandatory_options && mandatory_options.find { |option| options[option.to_sym].nil? }
          stdout.puts opts; exit
        end
      end

      SeleniumProxy::Server.start_service(options) do
        block.call stdout if block
      end
      SeleniumProxy::Server.thread.join if SeleniumProxy::Server.thread
    end
  end
end
