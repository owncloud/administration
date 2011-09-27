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
  method_option :server_type, :type => :string,
    :desc => "Server type", :required => true
  method_option :server, :type => :string,
    :desc => "Server name", :required => false
  method_option :user, :type => :string,
    :desc => "User name", :required => false
  method_option :password, :type => :string,
    :desc => "Password", :required => false
  method_option :skip_download, :type => :boolean,
    :desc => "Skip download of owncloud sources", :required => false
  def install
    installer = Installer.new @@settings

    installer.skip_download = options["skip_download"]

    installer.server = options["server"]
    installer.user = options["user"]
    installer.password = options["password"]
    
    server_type = options["server_type"]

    server_types = [ "local", "ftp" ]
    if server_types.include? server_type
      installer.install server_type
    else
      STDERR.puts "Unsupported server type '#{server_type}."
      STDERR.puts "Supported types are: #{server_types.join}."
      exit 1
    end
  end

  private
  
end
