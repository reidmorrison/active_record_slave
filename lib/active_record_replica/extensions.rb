require 'active_support/concern'
module ActiveRecordReplica
  module Extensions
    extend ActiveSupport::Concern

    [:select, :select_all, :select_one, :select_rows, :select_value, :select_values].each do |select_method|
      class_eval <<-RUBY, __FILE__, __LINE__ + 1
        def #{select_method}(sql, name = nil, *args, **kwargs)
          return super if active_record_replica_read_from_primary?
  
          ActiveRecordReplica.read_from_primary do
            reader_connection.#{select_method}(sql, "Replica: \#{name || 'SQL'}", *args, **kwargs)
          end
        end
      RUBY
    end

    def reader_connection
      Replica.connection
    end

    def begin_db_transaction
      return if ActiveRecordReplica.skip_transactions?
      return super unless ActiveRecordReplica.block_transactions?

      raise(TransactionAttempted, 'Attempting to begin a transaction during a read-only database connection.')
    end

    def commit_db_transaction
      return if ActiveRecordReplica.skip_transactions?
      return super unless ActiveRecordReplica.block_transactions?

      raise(TransactionAttempted, 'Attempting to commit a transaction during a read-only database connection.')
    end

    def create_savepoint(name = current_savepoint_name(true))
      return if ActiveRecordReplica.skip_transactions?
      return super unless ActiveRecordReplica.block_transactions?

      raise(TransactionAttempted, 'Attempting to create a savepoint during a read-only database connection.')
    end

    def rollback_to_savepoint(name = current_savepoint_name(true))
      return if ActiveRecordReplica.skip_transactions?
      return super unless ActiveRecordReplica.block_transactions?

      raise(TransactionAttempted, 'Attempting to rollback a savepoint during a read-only database connection.')
    end

    def release_savepoint(name = current_savepoint_name(true))
      return if ActiveRecordReplica.skip_transactions?
      return super unless ActiveRecordReplica.block_transactions?

      raise(TransactionAttempted, 'Attempting to release a savepoint during a read-only database connection.')
    end

    # Returns whether to read from the primary database
    def active_record_replica_read_from_primary?
      # Read from primary when forced by thread variable, or
      # in a transaction and not ignoring transactions
      ActiveRecordReplica.read_from_primary? ||
        (open_transactions > 0) && !ActiveRecordReplica.ignore_transactions?
    end
  end
end
