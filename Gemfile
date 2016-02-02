source "http://rubygems.org"
gemspec

gem "rake"

group :test do
  gem 'protected_attributes'
end

platforms :mri_18 do
  unless ENV["CI"]
    gem "ruby-debug"
  end
  gem "SystemTimer"
end

platforms :mri_19 do
  gem "bson_ext"
  unless ENV["CI"]
    gem "ruby-debug19", :require => "ruby-debug" if RUBY_VERSION < "1.9.3"
  end
end
