require 'spec_helper'

describe Alteration do
  describe "associations" do
    it { expect(subject).to belong_to :target_order }
    it { expect(subject).to belong_to :working_order }
  end
end
