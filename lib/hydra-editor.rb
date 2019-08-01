require 'hydra_editor/engine'

module HydraEditor
  class InvalidType < RuntimeError; end

  extend ActiveSupport::Autoload

  autoload :ControllerResource

  def self.models=(val)
    @models = val
  end

  def self.models
    @models ||= []
  end

  def self.valid_model?(type)
    models.include? type
  end

  class Config < OpenStruct; end

  def config_root_path
    Rails.root
  end

  def config_file
    return unless File.exist?(config_root_path.join("config", "hydra_editor.yml"))
    File.read(config_root_path.join("config", "hydra_editor.yml"))
  end

  def config_hash
    return {} unless config_file
    YAML.safe_load(ERB.new(config_file).result)[environment]
  end

  def config
    @config ||= Config.new(
      config_hash
    )
  end

  module_function :config, :config_hash, :config_file, :config_root_path
end
