# frozen_string_literal: true

module LogsForMyFamily
  module Sidekiq
    class Client
      def call(worker_class, job, queue, redis_pool)
        logger = LogsForMyFamily.logger
        if logger
          job['logsformyfamily.context'] = {
            request_id: logger.request_id,
            queue: queue
          }
        end
        yield
      end
    end

    class Server
      def call(worker, job, queue)
        logger = LogsForMyFamily::Logger.new.set_client_request_info(job['logsformyfamily.context'])
        logger.set_request_id(job['jid'])
        LogsForMyFamily.logger = logger
        yield
      end
    end
  end
end
