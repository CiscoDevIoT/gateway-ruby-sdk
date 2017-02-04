# coding: utf-8

Gem::Specification.new do |s|
  s.name        = 'cisco-deviot'
  s.version     = '0.1.0'
  s.summary     = 'Ruby SDK for DevIoT gateway service'
  s.email       = ['hhxiao@gmail.com']
  s.homepage    = 'https://github.com/CiscoDevIoT/gateway-ruby-sdk'
  s.description = 'Ruby SDK for DevIoT gateway service'
  s.has_rdoc    = false
  s.authors     = ['Hai-Hua Xiao']
  s.license     = 'Apache'
  s.files       = ['Gemfile', 'LICENSE.txt', 'README.md', 'cisco-deviot.gemspec'] + Dir['lib/**/*.rb']
  s.add_dependency 'mqtt', '>= 0.4.0'
  s.add_development_dependency 'bundler'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'test-unit'

end
