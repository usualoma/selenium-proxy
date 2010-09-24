require File.dirname(__FILE__) + '/spec_helper.rb'

require 'webrick'

describe SeleniumProxy do
  
  before :all do
    @access_log = StringIO.new
    @server_thread = Thread.new do
      @server = WEBrick::HTTPServer.new({
        :BindAddress => '127.0.0.1',
        :Logger      => WEBrick::Log.new(@access_log),
        :AccessLog   => [[@access_log, WEBrick::AccessLog::COMBINED_LOG_FORMAT]],
        :Port => 11111,
      })
      @server.mount_proc '/' do |req, res|
        res.body = <<-HTML
<html>
<head>
</head>
<body>
  content
</body>
</html>
        HTML
      end
      @server.start
    end
  end

  after :all do
    @server.shutdown if @server
    @server_thread.exit
    @server_thread.join
  end

  before :each do
    SeleniumProxy::Server.start_service
  end

  after :each do
    begin
      @browser.close
      @browser.stop
    rescue => e
      #
    end
    SeleniumProxy::Server.stop_service
  end

  browsers = ['*chrome', '*googlechrome', '*iexplore']
  #browsers << '*safari'
  #browsers << '*opera'

  browsers.each do |type|
    describe type do
      it "create" do
        begin
          @browser = SeleniumProxy::Server.browser({
            :type => type,
            :url  => 'http://localhost:11111/',
          })
          @browser.should be_instance_of SeleniumProxy::Browser
        rescue SeleniumCommandError => e
          #
        end
      end

      it "open" do
        begin
          @browser = SeleniumProxy::Server.browser({
            :type => type,
            :url  => 'http://localhost:11111/',
          })
          @browser.open '/'
        rescue SeleniumCommandError => e
          #
        else
          @browser.get_html_source.should match /content/
        end
      end
    end
  end
  
end
