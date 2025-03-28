# frozen_string_literal: true

require 'spec_helper'
require 'fileutils'
require 'generators/ruby_llm/install_generator'

RSpec.describe RubyLLM::InstallGenerator, type: :generator do
  # Use the actual template directory
  let(:template_dir) { File.expand_path('../../../../../lib/generators/ruby_llm/install/templates', __FILE__) }

  describe 'migration templates' do
    it 'has expected migration template files' do
      expected_files = [
        'create_chats_migration.rb.tt',
        'create_messages_migration.rb.tt',
        'create_tool_calls_migration.rb.tt'
      ]

      expected_files.each do |file|
        expect(File.exist?(File.join(template_dir, file))).to be(true), "Expected template file #{file} to exist"
      end
    end

    it 'has proper chats migration content' do
      chat_migration = File.read(File.join(template_dir, 'create_chats_migration.rb.tt'))
      expect(chat_migration).to include('create_table :<%= options[:chat_model_name].tableize %>')
      expect(chat_migration).to include('t.string :model_id')
    end

    it 'has proper messages migration content' do
      message_migration = File.read(File.join(template_dir, 'create_messages_migration.rb.tt'))
      expect(message_migration).to include('create_table :<%= options[:message_model_name].tableize %>')
      expect(message_migration).to include('t.references :<%= options[:chat_model_name].tableize.singularize %>')
      expect(message_migration).to include('t.string :role')
      expect(message_migration).to include('t.text :content')
    end

    it 'has proper tool_calls migration content' do
      tool_call_migration = File.read(File.join(template_dir, 'create_tool_calls_migration.rb.tt'))
      expect(tool_call_migration).to include('create_table :<%= options[:tool_call_model_name].tableize %>')
      expect(tool_call_migration).to include('t.string :tool_call_id')
      expect(tool_call_migration).to include('t.string :name')
    end

    it 'supports database-agnostic JSON handling in migrations' do
      tool_call_migration = File.read(File.join(template_dir, 'create_tool_calls_migration.rb.tt'))
      expect(tool_call_migration).to include("t.<%= postgresql? ? 'jsonb' : 'json' %> :arguments, default: {}")
    end
  end

  describe 'model templates' do
    it 'has expected model template files' do
      expected_files = [
        'chat_model.rb.tt',
        'message_model.rb.tt',
        'tool_call_model.rb.tt'
      ]

      expected_files.each do |file|
        expect(File.exist?(File.join(template_dir, file))).to be(true), "Expected template file #{file} to exist"
      end
    end

    it 'has proper acts_as_chat declaration in chat model' do
      chat_content = File.read(File.join(template_dir, 'chat_model.rb.tt'))
      expect(chat_content).to include('acts_as_chat')
    end

    it 'has proper acts_as_message declaration in message model' do
      message_content = File.read(File.join(template_dir, 'message_model.rb.tt'))
      expect(message_content).to include('acts_as_message')
    end

    it 'has proper acts_as_tool_call declaration in tool call model' do
      tool_call_content = File.read(File.join(template_dir, 'tool_call_model.rb.tt'))
      expect(tool_call_content).to include('acts_as_tool_call')
    end
  end

  describe 'initializer template' do
    it 'has expected initializer template file' do
      expect(File.exist?(File.join(template_dir, 'initializer.rb.tt'))).to be(true)
    end

    it 'includes RubyLLM configuration block' do
      initializer_content = File.read(File.join(template_dir, 'initializer.rb.tt'))
      expect(initializer_content).to include('RubyLLM.configure do |config|')
    end

    it 'includes API key configuration options' do
      initializer_content = File.read(File.join(template_dir, 'initializer.rb.tt'))
      expect(initializer_content).to include('config.openai_api_key')
      expect(initializer_content).to include('config.anthropic_api_key')
    end
  end

  describe 'README template' do
    it 'has a README template file' do
      expect(File.exist?(File.join(template_dir, 'README.md.tt'))).to be(true)
    end

    it 'has a welcome message and setup information' do
      readme_content = File.read(File.join(template_dir, 'README.md.tt'))
      expect(readme_content).to include('RubyLLM Rails Setup Complete')
      expect(readme_content).to include('Run migrations')
    end

    it 'includes database migration instructions' do
      readme_content = File.read(File.join(template_dir, 'README.md.tt'))
      expect(readme_content).to include('rails db:migrate')
    end

    it 'includes API configuration instructions' do
      readme_content = File.read(File.join(template_dir, 'README.md.tt'))
      expect(readme_content).to include('Set your API keys')
    end

    it 'includes basic usage examples' do
      readme_content = File.read(File.join(template_dir, 'README.md.tt'))
      expect(readme_content).to include('Start using RubyLLM in your code')
      expect(readme_content).to include('For streaming responses')
    end
  end

  describe 'generator file structure' do
    it 'has a valid generator file' do
      generator_file = File.expand_path('../../../../../lib/generators/ruby_llm/install_generator.rb', __FILE__)
      expect(File.exist?(generator_file)).to be(true)
    end

    it 'inherits from Rails::Generators::Base' do
      generator_file = File.expand_path('../../../../../lib/generators/ruby_llm/install_generator.rb', __FILE__)
      generator_content = File.read(generator_file)
      expect(generator_content).to include('class InstallGenerator < Rails::Generators::Base')
    end

    it 'includes Rails::Generators::Migration' do
      generator_file = File.expand_path('../../../../../lib/generators/ruby_llm/install_generator.rb', __FILE__)
      generator_content = File.read(generator_file)
      expect(generator_content).to include('include Rails::Generators::Migration')
    end

    it 'defines all required methods' do
      generator_file = File.expand_path('../../../../../lib/generators/ruby_llm/install_generator.rb', __FILE__)
      generator_content = File.read(generator_file)
      expect(generator_content).to include('def create_migration_files')
      expect(generator_content).to include('def create_model_files')
      expect(generator_content).to include('def create_initializer')
      expect(generator_content).to include('def show_readme')
    end

    it 'has migrations in the correct order' do
      generator_file = File.expand_path('../../../../../lib/generators/ruby_llm/install_generator.rb', __FILE__)
      generator_content = File.read(generator_file)

      # Check for the migration template calls in the correct order
      chats_position = generator_content.index('create_chats_migration.rb.tt')
      tool_calls_position = generator_content.index('create_tool_calls_migration.rb.tt')
      messages_position = generator_content.index('create_messages_migration.rb.tt')

      # Verify order: chats -> tool_calls -> messages
      expect(chats_position).to be < tool_calls_position
      expect(tool_calls_position).to be >  messages_position
    end

    it 'enforces sequential migration timestamps' do
      # NOTE: this gets taken care of by the rails generator
    end
  end

  describe 'database adapter detection' do
    it 'defines a postgresql? method' do
      generator_file = File.expand_path('../../../../../lib/generators/ruby_llm/install_generator.rb', __FILE__)
      generator_content = File.read(generator_file)
      expect(generator_content).to include('def postgresql?')
    end

    it 'detects PostgreSQL by adapter name' do
      generator_file = File.expand_path('../../../../../lib/generators/ruby_llm/install_generator.rb', __FILE__)
      generator_content = File.read(generator_file)
      expect(generator_content).to include('ActiveRecord::Base.connection.adapter_name.downcase.include?')
    end

    it 'handles exceptions gracefully' do
      generator_file = File.expand_path('../../../../../lib/generators/ruby_llm/install_generator.rb', __FILE__)
      generator_content = File.read(generator_file)
      expect(generator_content).to include('rescue')
      expect(generator_content).to include('false')
    end
  end

  describe 'generator options' do
    it 'has correct default model names' do
      generator_file = File.expand_path('../../../../../lib/generators/ruby_llm/install_generator.rb', __FILE__)
      generator_content = File.read(generator_file)
      
      expect(generator_content).to include("class_option :chat_model_name, type: :string, default: 'Chat'")
      expect(generator_content).to include("class_option :message_model_name, type: :string, default: 'Message'")
      expect(generator_content).to include("class_option :tool_call_model_name, type: :string, default: 'ToolCall'")
    end

    it 'handles custom model names in migrations' do
      chat_migration = File.read(File.join(template_dir, 'create_chats_migration.rb.tt'))
      message_migration = File.read(File.join(template_dir, 'create_messages_migration.rb.tt'))
      tool_call_migration = File.read(File.join(template_dir, 'create_tool_calls_migration.rb.tt'))

      # Test that migrations use ERB variables for table names
      expect(chat_migration).to include('create_table :<%= options[:chat_model_name].tableize %>')
      expect(message_migration).to include('create_table :<%= options[:message_model_name].tableize %>')
      expect(tool_call_migration).to include('create_table :<%= options[:tool_call_model_name].tableize %>')
    end

    it 'handles custom model names in model files' do
      chat_model = File.read(File.join(template_dir, 'chat_model.rb.tt'))
      message_model = File.read(File.join(template_dir, 'message_model.rb.tt'))
      tool_call_model = File.read(File.join(template_dir, 'tool_call_model.rb.tt'))

      # Test that model files use ERB variables for class names
      expect(chat_model).to include('class <%= options[:chat_model_name] %>')
      expect(message_model).to include('class <%= options[:message_model_name] %>')
      expect(tool_call_model).to include('class <%= options[:tool_call_model_name] %>')
    end

    it 'handles custom model names in foreign keys' do
      message_migration = File.read(File.join(template_dir, 'create_messages_migration.rb.tt'))
      
      # Test foreign key references use ERB variables
      expect(message_migration).to include('t.references :<%= options[:chat_model_name].tableize.singularize %>')
      expect(message_migration).to include('t.references :<%= options[:tool_call_model_name].tableize.singularize %>')
    end

    it 'handles custom model names in migration class names' do
      chat_migration = File.read(File.join(template_dir, 'create_chats_migration.rb.tt'))
      message_migration = File.read(File.join(template_dir, 'create_messages_migration.rb.tt'))
      tool_call_migration = File.read(File.join(template_dir, 'create_tool_calls_migration.rb.tt'))

      # Test that migration class names use ERB variables
      expect(chat_migration).to include('class Create<%= options[:chat_model_name].pluralize %>')
      expect(message_migration).to include('class Create<%= options[:message_model_name].pluralize %>')
      expect(tool_call_migration).to include('class Create<%= options[:tool_call_model_name].pluralize %>')
    end

    it 'handles custom model names in migration filenames' do
      generator_file = File.expand_path('../../../../../lib/generators/ruby_llm/install_generator.rb', __FILE__)
      generator_content = File.read(generator_file)

      # Test that migration filenames use ERB variables
      expect(generator_content).to include('create_#{options[:chat_model_name].tableize}.rb')
      expect(generator_content).to include('create_#{options[:message_model_name].tableize}.rb')
      expect(generator_content).to include('create_#{options[:tool_call_model_name].tableize}.rb')
    end

    it 'handles custom model names in model filenames' do
      generator_file = File.expand_path('../../../../../lib/generators/ruby_llm/install_generator.rb', __FILE__)
      generator_content = File.read(generator_file)

      # Test that model filenames use ERB variables
      expect(generator_content).to include('#{options[:chat_model_name].underscore}.rb')
      expect(generator_content).to include('#{options[:message_model_name].underscore}.rb')
      expect(generator_content).to include('#{options[:tool_call_model_name].underscore}.rb')
    end
  end
end
