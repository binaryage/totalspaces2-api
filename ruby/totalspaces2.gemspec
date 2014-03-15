Gem::Specification.new do |s|
  s.name = %q{totalspaces2}
  s.version = "2.0.1"

  s.authors = ["Stephen Sykes"]
  s.date = %q{2014-03-15}
  s.description = %q{This allows you to control the TotalSpaces2 desktop manager for mac from ruby.}
  s.email = %q{stephen@binaryage.com}
  s.files = [
    "README.rdoc",
    "MIT_LICENCE",
    "lib/totalspaces2.rb",
    "lib/libtotalspaces2api.dylib",
    "lib/TSLib.h"
  ]
  s.homepage = %q{https://github.com/binaryage/totalspaces2-api/tree/master/ruby}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.summary = %q{TotalSpaces2 control from ruby}
  s.add_dependency('ffi', '>= 1.0.11')
end
