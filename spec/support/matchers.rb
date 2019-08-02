# frozen_string_literal: true

RSpec::Matchers.define_negated_matcher :a_collection_excluding, :include
RSpec::Matchers.define_negated_matcher :not_change, :change

RSpec::Matchers.define :an_uuid do
  match do |actual|
    /^[0-9a-z]{8}-([0-9a-z]{4}-){3}[0-9a-z]{12}$/.match? actual
  end
end

RSpec::Matchers.alias_matcher :be_uuid, :an_uuid
