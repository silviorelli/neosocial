module Job
  class ImportMutualFriends
    include Sidekiq::Worker

    def perform(uid, person_id)
      user = User.find_by_uid(uid)
      person = user.client.get_object(person_id)
      friend = User.create_from_facebook(person)

      # Import mutual friends
      mutual_friends = user.client.get_connections("me", "mutualfriends/#{person_id}")

      commands = []

      # Make them friends
      mutual_friends.each do |mutual_friend|
        uid = mutual_friend["id"]

        node = User.find_by_uid(uid)
        unless node
          person = user.client.get_object(uid)
          node = User.create_from_facebook(person)
        end

        commands << [:create_unique_relationship, "friends_index", "ids",  "#{uid}-#{person_id}", "friends", node.neo_id, friend.neo_id]
        commands << [:create_unique_relationship, "friends_index", "ids",  "#{person_id}-#{uid}", "friends", friend.neo_id, node.neo_id]

      end

      batch_result = $neo_server.batch *commands
    end

  end
end