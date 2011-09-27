class Installer

  def initialize settings
    @settings = settings
  end

  def install
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

    @source_dir = @settings.tmp_dir + "owncloud"
    
    install_local
  end

  def install_local
    # Requirements for ownCloud to run:
    # * packages installed: apache2, apache2-mod_php5, php5-json, php5-dom,
    #   php5-sqlite, php5-mbstring
    # * apache2 running
    
    puts "Installing owncloud to web server..."
    http_docs_dir = "/srv/www/htdocs/"
    
    system "sudo cp -r #{@source_dir} #{http_docs_dir}"
    system "sudo chown -R wwwrun:www #{http_docs_dir}owncloud"
  end
  
end
