class Installer

  attr_accessor :server, :user, :password, :skip_download
  
  def initialize settings
    @settings = settings
  end

  def install server_type
    if !skip_download
      source = {
        :server => "owncloud.org",
        :path => "/releases/",
        :file => "owncloud-2b2.tar.bz2"
      }

      local_source = @settings.tmp_dir + source[:file]

      puts "Downloading owncloud source archive..."
      Net::HTTP.start( source[:server] ) do |http|
        response = http.get( source[:path] + source[:file] )
        open( local_source, "wb") do |file|
          file.write response.body
        end
      end

      puts "Extracting archive..."
      system "cd #{@settings.tmp_dir}; tar xjf #{source[:file]}"
    end

    @source_dir = @settings.tmp_dir + "owncloud"
    
    if server_type == "local"
      install_local
    elsif server_type == "ftp"
      install_ftp
    else
      STDERR.puts "Unsupported server type: #{server_type}"
      exit 1
    end
  end

  def install_local
    # Requirements for ownCloud to run:
    # * packages installed: apache2, apache2-mod_php5, php5-json, php5-dom,
    #   php5-sqlite, php5-mbstring
    # * apache2 running
    
    puts "Installing owncloud to local web server..."
    http_docs_dir = "/srv/www/htdocs/"
    
    system "sudo cp -r #{@source_dir} #{http_docs_dir}"
    system "sudo chown -R wwwrun:www #{http_docs_dir}owncloud"
  end
  
  def install_ftp
    puts "Installing owncloud to remote web server via FTP..."

    assert_options [ :server, :user, :password ]

    ftp = Net::FTP.new( server )
    ftp.passive = true
    puts "  Logging in..."
    ftp.login user, password

    puts "  Finding installation directory..."
    install_dir = ""
    [ "httpdocs" ].each do |d|
      dir = try_ftp_cd ftp, d
      if dir
        install_dir = dir
        break
      end
    end
    puts "  Installing to dir '#{install_dir}'..."
    puts "FIXME: actually install"
    
    puts "  Closing..."
    ftp.close
  end
  
  private

  def try_ftp_cd ftp, dir
    begin
      ftp.chdir dir
      return dir
    rescue Net::FTPPermError => e
      return nil
    end
  end
  
  def assert_options options
    @errors = Array.new
    options.each do |option|
      value = send option
      if value.nil?
        @errors.push "Missing option: #{option}"
      end
    end
    if !@errors.empty?
      STDERR.puts @errors.join( "\n" )
      exit 1
    end
  end
  
end
