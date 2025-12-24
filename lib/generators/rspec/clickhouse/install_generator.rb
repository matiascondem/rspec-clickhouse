# frozen_string_literal: true

require 'rails/generators'

module Rspec
  module Clickhouse
    module Generators
      class InstallGenerator < Rails::Generators::Base
        source_root File.expand_path('templates', __dir__)

        desc 'Generates rspec-clickhouse initializer and helper templates'

        def copy_initializer
          template 'initializer.rb.tt', 'config/initializers/clickhouse.rb'
        end

        def copy_helper_template
          template 'clickhouse_helper.rb.tt', 'spec/support/helpers/clickhouse_helper.rb'
        end

        def copy_factories_template
          template 'clickhouse_factories.rb.tt', 'spec/support/clickhouse_factories.rb'
        end

        def show_readme
          readme 'POST_INSTALL' if behavior == :invoke
        end

        private

        def app_name
          Rails.application.class.module_parent_name.underscore
        end
      end
    end
  end
end
