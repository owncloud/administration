#
# owncloud-admin - the owncloud administration tool
#
# Copyright (C) 2011 Cornelius Schumacher <schumacher@kde.org>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

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
    # Access <owncloud-server>/status.php (will be in 2beta3)
  end

  desc "install", "Install ownCloud server"
  method_option :server_type, :type => :string,
    :desc => "Server type (#{Installer.server_types.join(", ")})",
    :required => true
  method_option :server, :type => :string,
    :desc => "Server name", :required => false
  method_option :ftp_user, :type => :string,
    :desc => "FTP user name", :required => false
  method_option :ftp_password, :type => :string,
    :desc => "FTP password", :required => false
  method_option :root_helper, :type => :string,
    :desc => "Helper to call to run command as root (use 'kdesu -c' for GUI)",
    :required => false
  method_option :skip_download, :type => :boolean,
    :desc => "Skip download of owncloud sources", :required => false
  method_option :admin_user, :type => :string,
    :desc => "Name of ownCloud admin user (defaults to $USER)",
    :required => false
  method_option :admin_password, :type => :string,
    :desc => "Initial admin password", :required => true
  def install
    installer = Installer.new @@settings

    installer.skip_download = options["skip_download"]

    installer.server = options["server"]
    installer.ftp_user = options["ftp_user"]
    installer.ftp_password = options["ftp_password"]
    if options["root_helper"]
      installer.root_helper = options["root_helper"]
    else
      installer.root_helper = "sudo bash -c"
    end
    installer.admin_user = options["admin_user"]
    installer.admin_password = options["admin_password"]
    
    server_type = options["server_type"]

    if Installer.server_types.include? server_type
      installer.install server_type
    else
      STDERR.puts "Unsupported server type '#{server_type}."
      STDERR.puts "Supported types are: #{Installer.server_types.join(", ")}."
      exit 1
    end
  end

  private
  
end
