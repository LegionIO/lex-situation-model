# frozen_string_literal: true

require_relative 'lib/legion/extensions/situation_model/version'

Gem::Specification.new do |spec|
  spec.name          = 'lex-situation-model'
  spec.version       = Legion::Extensions::SituationModel::VERSION
  spec.authors       = ['Esity']
  spec.email         = ['matthewdiverson@gmail.com']

  spec.summary       = 'LEX Situation Model'
  spec.description   = 'Zwaan Event Indexing Model for brain-modeled agentic AI: tracks 5-dimensional situation models across narrative events'
  spec.homepage      = 'https://github.com/LegionIO/lex-situation-model'
  spec.license       = 'MIT'
  spec.required_ruby_version = '>= 3.4'

  spec.metadata['homepage_uri']      = spec.homepage
  spec.metadata['source_code_uri']   = 'https://github.com/LegionIO/lex-situation-model'
  spec.metadata['documentation_uri'] = 'https://github.com/LegionIO/lex-situation-model'
  spec.metadata['changelog_uri']     = 'https://github.com/LegionIO/lex-situation-model'
  spec.metadata['bug_tracker_uri']   = 'https://github.com/LegionIO/lex-situation-model/issues'
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir.glob('{lib,spec}/**/*') + %w[lex-situation-model.gemspec Gemfile LICENSE README.md]
  end
  spec.require_paths = ['lib']
end
