# frozen_string_literal: true

module Mongoid
  module Validatable

    # Validates whether or not an association is valid or not. Will correctly
    # handle has one and has many associations.
    #
    # @example Set up the association validations.
    #
    #   class Person
    #     include Mongoid::Document
    #     embeds_one :name
    #     embeds_many :addresses
    #
    #     validates_associated :name, :addresses
    #   end
    class AssociatedValidator < ActiveModel::Validator
      # Required by `validates_with` so that the validator
      # gets added to the correct attributes.
      def attributes
        options[:attributes]
      end

      # Checks that the named associations of the given record
      # (`attributes`) are valid. This does NOT load the associations
      # from the database, and will only validate records that are dirty
      # or unpersisted.
      #
      # If anything is not valid, appropriate errors will be added to
      # the `document` parameter.
      #
      # @param [ Mongoid::Document ] document the document with the
      #   associations to validate.
      def validate(document)
        options[:attributes].each do |attr_name|
          validate_association(document, attr_name)
        end
      end

      private

      # Validates that every already-loaded child of the given association is
      # valid, skipping those flagged for destroy. Otherwise, the appropriate
      # errors will be added to the parent document.
      #
      # getaroom fork override: upstream only validates children that are new
      # or changed. That breaks child validations that depend on the parent: if
      # only the parent changes, a saved child is never re-checked, and the
      # parent saves even though the child is now invalid. This is the behavior
      # of our old `8.1-stable-sc` branch. Upstream tried to fix it
      # (MONGOID-5822) and reverted the fix (#6014).
      #
      # Like upstream, this never loads the association: it inspects the
      # proxy via `document.ivar(attribute)`, so only children already in
      # memory are validated. Reading the attribute instead would load every
      # unloaded child on each save and make unrelated saves fail on legacy
      # data in children nothing touched.
      #
      # Removing this override: restore the upstream condition
      # `(!value.persisted? || value.changed?)` in the block below once either
      #
      # * upstream ships a fix for MONGOID-5822 that validates unchanged
      #   children when the parent changes, or
      # * the app no longer has child validations that read the parent.
      #   Search for `validate` blocks and validators on embedded or
      #   has_many children that call `parent` / the inverse association.
      #
      # What can break when rebasing onto a newer Mongoid: the pieces this
      # method touches, #validating, #flagged_for_destroy? and #validated?,
      # and #get_target_documents below. The specs in
      # spec/mongoid/validatable/associated_all_children_spec.rb cover the
      # behavior.
      #
      # @param [ Document ] document The document to validate.
      # @param [ Symbol ] attribute The association to validate.
      def validate_association(document, attribute)
        # Grab the proxy from the instance variable directly; we don't want
        # any loading logic to run.
        proxy = document.ivar(attribute)
        return unless proxy

        # It might be a literal document instead of a proxy if this document
        # was created with a Document instance as a provided attribute.
        target = proxy.respond_to?(:_target) ? proxy._target : proxy
        list = get_target_documents(target)

        valid = document.validating do
          # Use map.all? instead of all?, which would short-circuit on the
          # first failed validation.
          list.map do |value|
            if value && !value.flagged_for_destroy?
              value.validated? ? true : value.valid?
            else
              true
            end
          end.all?
        end

        document.errors.add(attribute, :invalid) unless valid
      end

      private

      # Examine the given target object and return an array of
      # documents (possibly empty) that the target represents.
      #
      # @param [ Array | Mongoid::Document | Mongoid::Association::Proxy | HasMany::Enumerable ] target
      #   the target object to examine.
      #
      # @return [ Array<Mongoid::Document> ] the list of documents
      def get_target_documents(target)
        if target.respond_to?(:_loaded?)
          get_target_documents_for_has_many(target)
        else
          get_target_documents_for_other(target)
        end
      end

      # Returns the list of all currently in-memory values held by
      # the target. The target will not be loaded.
      #
      # @param [ HasMany::Enumerable ] target the target that will
      #   be examined for in-memory documents.
      #
      # @return [ Array<Mongoid::Document> ] the in-memory documents
      #   held by the target.
      def get_target_documents_for_has_many(target)
        [ *target._loaded.values, *target._added.values ]
      end

      # Returns the target as an array. If the target represents a single
      # value, it is wrapped in an array.
      #
      # @param [ Array | Mongoid::Document | Mongoid::Association::Proxy ] target
      #   the target to return.
      #
      # @return [ Array<Mongoid::Document> ] the target, as an array.
      def get_target_documents_for_other(target)
        Array.wrap(target)
      end
    end
  end
end
