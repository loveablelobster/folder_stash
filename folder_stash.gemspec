# frozen_string_literal: true

Gem::Specification.new do |s|
  s.name = 'folder_stash'
  s.version = '0.0.1'
  s.summary = 'Keeps the number of files per directory within a limit by'\
              ' autogenerating subdirectories.'
  s.author = 'Martin Stein'
  s.files = Dir['{lib}/**/*.rb', 'bin/*', 'LICENSE', '*.rdoc']
  s.homepage = 'https://github.com/loveablelobster/folder_stash'
  s.license = 'MIT'
  s.email = 'loveablelobster@fastmail.fm'
  s.description = <<~DESCRIPTION
    The folder_stash gem will store files in a directory with a user definable
    number of nested subdirectories in a given path and a maximum number of
    items allowed per subdirectory.
    New nested subdirectories will be created on demand as a given subdirectory
    reaches the specified limit of items. All created subdirectories will have
    randomized base names.
  DESCRIPTION
end
