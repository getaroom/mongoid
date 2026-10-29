# frozen_string_literal: true

require "spec_helper"

# Covers the getaroom override of Batchable#pre_process_batch_insert, which
# restores the pre-8.1.12 (MONGOID-4889) one-at-a-time append behavior.
describe "Embedded batch insert" do

  let(:person) do
    Person.create!
  end

  let(:persisted_streets) do
    Person.collection.find(_id: person.id).first["addresses"]&.map { |a| a["street"] }
  end

  context "when appending children built with the inverse already set" do

    let(:addresses) do
      %w[a b].map { |street| Address.new(street: street, addressable: person) }
    end

    before do
      person.addresses << addresses
    end

    it "persists the children" do
      expect(persisted_streets).to eq(%w[a b])
    end

    it "marks the children persisted" do
      expect(addresses).to all(be_persisted)
    end
  end

  context "when assigning to a relation with an order option" do

    before do
      person.videos = [ Video.new(title: "a"), Video.new(title: "b") ]
      person.save!
      person.videos = [ person.videos.last, person.videos.first, Video.new(title: "c") ]
    end

    it "keeps the assigned order in memory" do
      expect(person.videos.map(&:title)).to eq(%w[b a c])
    end
  end
end
