# frozen_string_literal: true

lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require "mongoid/version"

Gem::Specification.new do |s|
  s.name        = "mongoid"
  s.version     = Mongoid::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["The MongoDB Ruby Team"]
  s.email       = "dbx-ruby@mongodb.com"
  s.homepage    = "https://mongoid.org"
  s.summary     = "Elegant Persistence in Ruby for MongoDB."
  s.description = "Mongoid is an ODM (Object Document Mapper) Framework for MongoDB, written in Ruby."
  s.license     = "MIT"

  s.metadata = {
    'bug_tracker_uri' => 'https://jira.mongodb.org/projects/MONGOID',
    'changelog_uri' => 'https://github.com/mongodb/mongoid/releases',
    'documentation_uri' => 'https://www.mongodb.com/docs/mongoid/',
    'homepage_uri' => 'https://mongoid.org/',
    'source_code_uri' => 'https://github.com/mongodb/mongoid',
  }

  s.required_ruby_version     = ">= 2.6"
  s.required_rubygems_version = ">= 1.3.6"

  # Ruby 3.0 requires ActiveModel 6.0 or higher.
  # activemodel 7.0.0 cannot be used due to Class#descendants issue
  # See: https://github.com/rails/rails/pull/43951
  #
  # getaroom fork override: the upper bound is widened from '<8.1' to '<8.2' so
  # this 8.1.x line can be used with Rails 8.1. Upstream made the same change
  # for Rails 8.1 on master and 9.0-stable (#6054, #6059; gemspec and CI only,
  # no lib/ changes) but never backported it to 8.1-stable, so upstream CI does
  # not run the 8.1.x suite against Rails 8.1.
  #
  # Removing this override: drop it once we are on a Mongoid release whose own
  # gemspec already allows the Rails version we run (9.0.x does), or once
  # upstream backports the bound to 8.1-stable. At that point the fork's
  # remaining overrides (see Batchable#pre_process_batch_insert) are the only
  # reason left to stay on it.
  #
  # What can break: Rails 8.1 changes to ActiveModel/ActiveSupport internals
  # that Mongoid 8.1.x touches, such as callbacks, validations, dirty tracking
  # and i18n. These show up as failures in the app's suite on Rails 8.1, not as
  # a bundler error. If one appears, patch it in the fork next to this line, or
  # narrow the bound back to '<8.1' and stay on Rails 8.0 until it is fixed.
  s.add_dependency("activemodel", ['>=5.1', '<8.2', '!= 7.0.0'])
  s.add_dependency("mongo", ['>=2.18.0', '<3.0.0'])
  s.add_dependency("concurrent-ruby", ['>= 1.0.5', '< 2.0'])

  # The ruby2_keywords gem is recommended for handling argument delegation issues,
  # especially if support for 2.6 or prior is required.
  # See https://www.ruby-lang.org/en/news/2019/12/12/separation-of-positional-and-keyword-arguments-in-ruby-3-0/#delegation
  #
  # We have a bunch of complex delegation logic, including various method_missings.
  # If we try to fix them "right", it will add too much logic. We will have to
  # handle different Ruby versions (including minor ones, Ruby 2.6 and 2.7
  # behave differently), hash key types (strings vs symbols), ways of passing
  # arguments (with curly braces vs without ones).
  #
  # Therefore, usage of this gem looks like a reasonable solution at the moment.
  s.add_dependency("ruby2_keywords", "~> 0.0.5")

  s.add_development_dependency("bson", ['>=4.14.0', '<5.0.0'])

  s.files        = Dir.glob("lib/**/*") + %w(CHANGELOG.md LICENSE README.md Rakefile)
  s.test_files   = Dir.glob("spec/**/*")
  s.require_path = 'lib'
end
