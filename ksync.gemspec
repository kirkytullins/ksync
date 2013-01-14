Gem::Specification.new do |s|
  s.name        = %q{ksync}
  s.version     = %q{0.5.1}
  s.license     = %q{MIT}
  s.date        = %q{2013-01-07}
  s.summary     = %q{A simple file backup/syncing class}
  s.description = %q{ksync is a simple class which is used to sync between 2 folders, the destination folder being used as a backup repository}
  s.authors     = [%q{Kirk Adoniadis}]
  s.email       = %q{kiriakos.adoniadis@gmail.com}
  s.files       = %w[README MIT-LICENSE Rakefile.rb lib/ksync.rb bin/ksync]
  s.homepage    = %q<http://rubygems.org/gems/ksync>
  s.executables = [%q<ksync>]
  s.add_development_dependency(%q<turn>, [%q{~> 0.9}])
  s.add_development_dependency(%q<minitest>, [%q{~> 4.4}])
  s.required_ruby_version = %q{>= 1.9.2}
  s.extra_rdoc_files = %w[README MIT-LICENSE]
  s.test_files = Dir.glob('test/test_*.rb')
end