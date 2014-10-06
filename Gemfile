source ENV['GEM_SOURCE'] || "https://rubygems.org"

#gem 'hocon', '~> 0.0.5',         :require => false

group :development, :test do
  gem 'rake',                    :require => false
  gem 'rspec', '~> 2.11',        :require => false
  gem 'rspec-puppet',            :require => false
  gem 'puppetlabs_spec_helper',  :require => false
  gem 'serverspec',              :require => false
  gem 'puppet-lint',             :require => false
  gem 'beaker',                  :require => false
  gem 'beaker-rspec', '>= 2.2',  :require => false
  gem 'pry',                     :require => false
  gem 'simplecov',               :require => false
end

if facterversion = ENV['FACTER_GEM_VERSION']
  gem 'facter', facterversion, :require => false
else
  gem 'facter', :require => false
end

if puppetversion = ENV['PUPPET_GEM_VERSION']
  gem 'puppet', puppetversion, :require => false
else
  gem 'puppet', :require => false
end

gem 'hocon', '~> 0.0.5',       :require => false

# vim:ft=ruby
