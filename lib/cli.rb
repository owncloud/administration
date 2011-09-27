class Cli < Thor

  default_task :global

  class_option :version, :type => :boolean, :desc => "Show version"

  def self.settings= s
    @@settings = s
  end

  desc "global", "Global options", :hide => true
  def global
    if options[:version]
      puts "owncloud-admin: #{@@settings.version}"
    else
      Cli.help shell
    end
  end

  desc "config", "Show and modify configuration"
  method_option :set_server, :type => :string, :aliases => "-s",
    :desc => "Set server"
  def config
    if options[:set_server]
      puts "SET SERVER TO #{options[:set_server]}"
    else
      puts "SHOW CONFIG"
    end
  end

  desc "ping", "Ping server"
  def ping
    puts "PING SERVER"
  end

  desc "install", "Install ownCloud server"
  def install
    puts "INSTALL"
  end

  private
  
end
