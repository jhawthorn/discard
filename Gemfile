source 'https://rubygems.org'

rails_version = ENV['RAILS_VERSION']
gem 'activerecord', rails_version

if rails_version == '~> 6.1.0'
  gem 'concurrent-ruby', '1.3.4'
end

if sqlite_version = ENV['SQLITE_VERSION']
  gem 'sqlite3', sqlite_version
end

# Specify your gem's dependencies in discard.gemspec
gemspec
