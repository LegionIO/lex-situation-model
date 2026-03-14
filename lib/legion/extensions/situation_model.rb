# frozen_string_literal: true

require 'legion/extensions/situation_model/version'
require 'legion/extensions/situation_model/helpers/constants'
require 'legion/extensions/situation_model/helpers/situation_event'
require 'legion/extensions/situation_model/helpers/situation_model'
require 'legion/extensions/situation_model/helpers/situation_engine'
require 'legion/extensions/situation_model/runners/situation_model'
require 'legion/extensions/situation_model/helpers/client'
require 'legion/extensions/situation_model/client'

module Legion
  module Extensions
    module SituationModel
      extend Legion::Extensions::Core if Legion::Extensions.const_defined? :Core
    end
  end
end
