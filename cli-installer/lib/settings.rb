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
