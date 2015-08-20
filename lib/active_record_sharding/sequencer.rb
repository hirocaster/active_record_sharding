require 'active_support/concern'

module ActiveRecordSharding
  module Sequencer
    extend ActiveSupport::Concern

    included do
      class_attribute :sequencer_repository, instance_writer: false
      class_attribute :sequencer_name, instance_writer: false
      class_attribute :sequencer_config, instance_writer: false
    end

    module ClassMethods
      def use_sequencer(name)
        self.sequencer_name = name
        self.sequencer_config = ActiveRecordSharding.config.fetch_sequencer_config name
        self.sequencer_repository = ActiveRecordSharding::SequencerRepository.new sequencer_config, self
        self.abstract_class = true
      end

      def current_sequence_id
        # for sqlite
        connection = sequencer_repository.fetch(sequencer_name).connection
        res = connection.execute "SELECT id FROM #{sequencer_config.table_name}"
        now_id = res.first.first.second.to_i
        now_id
      end

      def next_sequence_id
        connection = sequencer_repository.fetch(sequencer_name).connection

        # for MySQL
        # connection.execute "UPDATE #{quoted_table_name} SET id = LAST_INSERT_ID(id +1)"
        # res = connection.execute("SELECT LAST_INSERT_ID()")
        # new_id = res.first.first.to_i

        # for sqlite
        connection.execute "UPDATE #{sequencer_config.table_name} SET id=id+1"
        res = connection.execute "SELECT id FROM #{sequencer_config.table_name}"
        new_id = res.first.first.second.to_i
        new_id
      end
    end
  end
end
