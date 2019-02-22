module Mautic
  class Contact < Model

    alias_attribute :first_name, :firstname
    alias_attribute :last_name, :lastname
    def self.in(connection)
      Proxy.new(connection, endpoint, default_params: { search: '!is:anonymous' })
    end

    def self.get_segment_memberships
      contact_id = self.is_a?(Mautic::Contact) ? self.id : self
      segments = @connection.request(:get, %(api/contacts/#{contact_id}/segments))["lists"].values
      return segments
    end
    
    def assign_attributes(source = {})
      super
      self.attributes = {
        tags: (source['tags'] || []).collect{|t| Mautic::Tag.new(@connection, t)},
        doNotContact: source['doNotContact'],
      } if source
    end

    def add_dnc(comments: '')
      begin
        json = @connection.request(:post, "api/contacts/#{id}/dnc/email/add", { body: {comments: comments} })
        clear_changes
      rescue ValidationError => e
        self.errors = e.errors
      end

      self.errors.blank?
    end

    def remove_dnc
      begin
        json = @connection.request(:post, "api/contacts/#{id}/dnc/email/remove", { body: {} })
        clear_changes
      rescue ValidationError => e
        self.errors = e.errors
      end

      self.errors.blank?
    end

    def dnc?
      doNotContact.present?
    end

  end
end
