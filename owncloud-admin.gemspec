# -*- encoding: utf-8 -*-
require File.expand_path("../lib/version", __FILE__)

Gem::Specification.new do |s|
  s.name        = "owncloud-admin"
  s.version     = OwncloudAdmin::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Cornelius Schumacher']
  s.email       = ['cschum@suse.de']
  s.homepage    = "https://github.com/opensuse/owncloud-admin"
  s.summary     = "ownCloud administration"
  s.description = "Command line tool for installing and administering ownCloud"

  s.required_rubygems_version = ">= 1.3.6"
  s.rubyforge_project         = "inqlude"

  s.add_dependency "thor", ">=0.14.0"

  s.files        = `git ls-files`.split("\n")
  s.executables  = `git ls-files`.split("\n").map{|f| f =~ /^bin\/(.*)/ ? $1 : nil}.compact
  s.require_path = 'lib'
end
