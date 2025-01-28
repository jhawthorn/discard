# frozen_string_literal: true

module Discard
  RSpec.describe Configuration do
    describe '#default' do
      specify do
        expect(subject.discard_column).to eql(:discarded_at)
      end
    end
  end
end
