$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

require 'selenium'
require 'drb/drb'

module SeleniumProxy
  VERSION = '0.0.2'

  class Browser
    def initialize(opts = {})
      @drb     = opts[:drb]
      @browser = opts[:browser]
      @options = opts[:options]
    end

    def method_missing(name, *args)
      if @browser
        @browser.send name, *args
      else
        @drb.browser_call @options, name, *args
      end
    end
  end

  class Server
    attr_accessor :stream, :current_browser

    @@default_browser = '*chrome'
    @@default_drb_uri = 'druby://localhost:12445'
    @@default_serenium_host = 'localhost'
    @@default_serenium_port = 4444

    def self.browser(opts = {})
      drb, browser = nil, nil
      begin
        drb = DRbObject.new_with_uri(self.drb_uri(opts))
        drb.alive? if drb.respond_to?(:alive?)
      rescue DRb::DRbConnError => e
        browser = self.new(StringIO.new).browser(opts)
      end

      Browser.new({
        :drb     => drb,
        :browser => browser,
        :options => opts,
      })
    end

    def self.default_drb_uri
      @@default_drb_uri
    end

    def self.drb_uri(opts = {})
      opts[:drb_uri] || ENV['SELENIUM_PROXY_DRB_URI'] || self.default_drb_uri
    end

    def self.start_service(opts = {}, &block)
      DRb.start_service(self.drb_uri(opts), self.new)
      yield if block
    end

    def self.stop_service(&block)
      DRb.stop_service
    end

    def self.thread
      DRb.thread
    end

    def initialize(stream = $stdout)
      @stream  = stream
      @current_browser = @@default_browser
      @current_url = nil
      @browsers = {}
    end

    def browser_call(opts, name, *args)
      self.browser(opts).send name, *args
    end

    def browser(opts = {})
      opts[:type] = @current_browser = opts[:type] || @current_browser
      opts[:url]  = @current_url     = opts[:url]  || @current_url
      @browsers[@current_url.to_s + @current_browser.to_s] ||= new_browser(opts)
    end

    def new_browser(opts = {})
      browser = Selenium::SeleniumDriver.new(
        opts[:serenium_host] || ENV['SELENIUM_PROXY_SERENIUM_HOST'] || @@default_serenium_host,
        opts[:serenium_port] || ENV['SELENIUM_PROXY_SERENIUM_PORT'] || @@default_serenium_port,
        opts[:type],
        opts[:url],
        opts[:serenium_timeout] || ENV['SELENIUM_PROXY_SERENIUM_TIMEOUT'] || nil
      )
      browser.start
      browser
    end

  end
end
