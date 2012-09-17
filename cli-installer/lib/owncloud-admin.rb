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

require "rubygems"

require "thor"
require "net/http"
require "net/ftp"

require File.expand_path('../version', __FILE__)
require File.expand_path('../installer', __FILE__) # must be before cli
require File.expand_path('../cli', __FILE__)
require File.expand_path('../settings', __FILE__)
