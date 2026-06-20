require_relative './lib/CalDAV/VERSION'

class Gem::Specification
  def dependencies=(gems)
    gems.each{|gem| add_dependency(*gem)}
  end

  def development_dependencies=(gems)
    gems.each{|gem| add_development_dependency(*gem)}
  end
end

Gem::Specification.new do |spec|
  spec.name = 'caldav.rb'
  spec.version = CalDAV::VERSION

  spec.summary = "A Ruby CalDAV client library."
  spec.description = "A Ruby CalDAV client library, built on webdav (RFC 4791)."

  spec.author = 'thoran'
  spec.email = 'code@thoran.com'
  spec.homepage = 'https://github.com/thoran/caldav'
  spec.license = 'MIT'

  spec.required_ruby_version = '>= 3.2'
  spec.require_paths = ['lib']

  spec.files = [
    'caldav.rb.gemspec',
    'CHANGELOG',
    'Gemfile',
    'LICENSE',
    'Rakefile',
    'README.md',
    Dir['lib/**/*.rb'],
    Dir['test/**/*.rb']
  ].flatten

  spec.dependencies = [
    ['webdav', '~> 0.2']
  ]

  spec.development_dependencies = [
    ['minitest', '~> 6.0'],
    ['minitest-mock'],
    ['rake'],
    ['vcr', '~> 6.0'],
    ['webmock', '~> 3.0']
  ]
end
