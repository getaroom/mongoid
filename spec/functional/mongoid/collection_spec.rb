require "spec_helper"
require 'debugger'

describe Mongoid::Collection do

  describe "#initialize" do

    context "when providing options" do
      let(:capped) do
        described_class.new(
          Person,
          "capped_person",
          :capped => true,
          :size => 10240,
          :max => 100
        )
      end

      let(:options) do
        capped.options
      end

      it "sets the capped option" do
        options["capped"].should be_truthy
      end

      it "sets the capped size" do
        options["size"].should eq(10240)
      end

      it "sets the max capped documents" do
        options["max"].should eq(100)
      end
    end

    context "capped size not multiples of 256" do
      shared_examples 'rounded capped size' do |size, expectation|
        it 'rounds the capped size up to a multiple of 256, 4096 being the minimum' do
          unique = SecureRandom.hex

          c = described_class.new(Person, "person_#{unique}", capped: true, size: size)
          c.options['size'].should eq(expectation)
        end
      end

      it_behaves_like 'rounded capped size', 50, 4096
      it_behaves_like 'rounded capped size', 10000, 10240
      it_behaves_like 'rounded capped size', 10400, 10496

    end
  end
end
