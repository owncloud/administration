class Settings

  def version
    OwncloudAdmin::VERSION
  end

  def tmp_dir
    local_dir "tmp/"
  end

  private
  
  def local_path dirname
    home = ENV["HOME"] + "/.owncloud-admin/"
    Dir::mkdir home unless File.exists? home
    home + dirname
  end

  def local_dir dirname
    path = local_path dirname
    Dir::mkdir path unless File.exists? path
    path
  end

end
