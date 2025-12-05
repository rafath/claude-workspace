module Identity::Joinable
  extend ActiveSupport::Concern

  # An updated joinable concern to allow users to be reinstated to their original identity.
  # doesn't activate the race condition if `identity: nil` is removed from `deactivate` method in the user.rb model.
  # allows for seamless UI traversal in the existing code
  # redeem_if (increment new user count) is handled correctly (no increment if re-instating a user)

  def join(account, **attributes)
    attributes[:name] ||= email_address

    transaction do
      user = account.users.find_or_initialize_by(identity: self)
      reactivating = user.persisted? && !user.active?

      user.assign_attributes(attributes.merge(active: true))
      user.save!

      user.send(:grant_access_to_boards) if reactivating

      user.previously_new_record?
    end
  end
end
