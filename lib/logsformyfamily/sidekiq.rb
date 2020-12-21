# frozen_string_literal: true

module LogsForMyFamily
  module Sidekiq
    class Client
      def call(worker_class, job, queue, redis_pool)
        logger = Thread.current.thread_variable_get(:'logsformyfamily.logger')
        if logger
          job[:'logsformyfamily.context'] = {
            request_id: logger.request_id,
            queue: queue
          }
        end
        yield
      end
    end

    class Server
      def call(worker, job, queue)
        begin
          logger = LogsForMyFamily::Logger.new.set_client_request_info(job[:'logsformyfamily.context'])
          LogsForMyFamily.logger = logger
          yield
        rescue => ex
          puts ex.message
        end
      end
    end
  end
end
