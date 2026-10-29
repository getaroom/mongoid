# frozen_string_literal: true

require "spec_helper"

# Covers the getaroom override of AssociatedValidator#validate_association,
# which validates every loaded child instead of only new or changed ones.
module AssociatedAllChildrenSpec
  class Parent
    include Mongoid::Document

    store_in collection: "test_associated_all_children_parents"

    field :kind, type: String

    embeds_many :children, class_name: "AssociatedAllChildrenSpec::Child"
  end

  class Child
    include Mongoid::Document

    embedded_in :parent, class_name: "AssociatedAllChildrenSpec::Parent"

    field :name, type: String

    # Depends on the parent's value, not on any of the child's own fields.
    validate { errors.add(:base, "not allowed for kind") if parent&.kind == "restricted" }
  end
end

describe Mongoid::Validatable::AssociatedValidator do

  let(:parent) do
    AssociatedAllChildrenSpec::Parent.create!(
      kind: "open", children: [ { name: "persisted" } ]
    ).reload
  end

  it "validates persisted, unchanged children when the parent changes" do
    child = parent.children.first
    expect(child).to be_persisted
    expect(child).not_to be_changed

    parent.kind = "restricted"

    expect(parent).not_to be_valid
    expect(parent.errors[:children]).to be_present
  end

  it "does not load or validate an association that was never accessed" do
    parent = AssociatedAllChildrenSpec::Parent.find(self.parent.id)
    parent.kind = "restricted"

    expect(parent.ivar(:children)).to be_falsey
    expect(parent).to be_valid
    expect(parent.ivar(:children)).to be_falsey
  end

  it "is valid when no child validation fails" do
    parent.kind = "other"
    expect(parent).to be_valid
  end

  it "skips children flagged for destroy" do
    parent.children.first.flagged_for_destroy = true
    parent.kind = "restricted"

    expect(parent).to be_valid
  end
end
