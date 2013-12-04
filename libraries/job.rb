#
# Cookbook Name:: jenkins
# HWRP:: job
#
# Author:: Seth Vargo <sethvargo@gmail.com>
#
# Copyright 2013, Opscode, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

#
#
#
class Chef
  class Resource::JenkinsJob < Resource
    identity_attr :name

    attr_writer :enabled, :exists

    def initialize(name, run_context = nil)
      super

      # Set the resource name and provider
      @resource_name = :jenkins_job
      @provider = Provider::JenkinsJob

      # Set default actions and allowed actions
      @action = :create
      @allowed_actions.push(:create, :delete, :disable, :enable)

      # Set the name attribute and default attributes
      @name   = name

      # State attributes that are set by the provider
      @exists  = false
      @enabled = false
    end

    def name(arg = nil)
      set_or_return(:name, arg, kind_of: String)
    end

    def config(arg = nil)
      set_or_return(:config, arg, kind_of: String)
    end

    #
    # Determine if the job exists on the server. This value is set by the
    # provider when the current resource is loaded.
    #
    # @return [Boolean]
    #
    def exists?
      !!@exists
    end

    #
    # Determine if the job is enabled on the server. This value is set by the
    # provider when the current resource is loaded.
    #
    # @return [Boolean]
    #
    def enabled?
      !!@enabled
    end
  end
end

#
#
#
class Chef
  class Provider::JenkinsJob < Provider
    class JobDoesNotExist < StandardError
      def initialize(job, action)
        super "The Jenkins job `#{job}` does not exist. In order to " \
              "#{action} `#{job}`, that job must first exist on the " \
              "Jenkins server!"
      end
    end

    require 'rexml/document'

    include Jenkins::Helper

    def load_current_resource
      Chef::Log.debug("Loading current resource #{new_resource}")

      @current_resource = Resource::JenkinsJob.new(new_resource.name)
      @current_resource.name(new_resource.name)
      @current_resource.config(new_resource.config)

      if current_job
        @current_resource.exists  = true
        @current_resource.enabled = current_job[:enabled]
      else
        @current_resource.exists  = false
        @current_resource.enabled = false
      end
    end

    #
    # This provider supports why-run mode.
    #
    def whyrun_supported?; true; end

    #
    # Idempotently create a new Jenkins job with the current resource's name
    # and configuration file. If the job already exists, no action will be
    # taken. If the job does not exist, one will be created from the given
    # `config` XML file using the Jenkins CLI.
    #
    # This method also ensures the given configuration file matches the one
    # rendered on the server. If the configuration file does not match, a new
    # one is rendered.
    #
    # Requirements:
    #   - `config` parameter
    #
    def action_create
      validate_config!

      if current_resource.exists?
        Chef::Log.debug("#{new_resource} exists - skipping")
      else
        converge_by("Create #{new_resource}") do
          executor.execute!('create-job', new_resource.name, '<', new_resource.config)
        end
      end

      if has_correct_config?
        Chef::Log.debug("#{new_resource} config up to date - skipping")
      else
        converge_by("Update #{new_resource} config") do
          executor.execute!('update-job', new_resource.name, '<', new_resource.config)
        end
      end
    end

    #
    # Idempotently delete a Jenkins job with the current resource's name. If
    # the job does not exist, no action will be taken. If the job does exist,
    # it will be deleted using the Jenkins CLI.
    #
    def action_delete
      if current_resource.exists?
        converge_by("Delete #{new_resource}") do
          executor.execute!('delete-job', new_resource.name)
        end
      else
        Chef::Log.debug("#{new_resource} does not exist - skipping")
      end
    end

    #
    # Disable an existing Jenkins job. After some careful discussions
    # internally, it was decided that raising an exception when the job
    # does not exist is the best developer experience.
    #
    # @raise [JobDoesNotExist]
    #   if the job does not exist
    #
    def action_disable
      unless current_resource.exists?
        raise JobDoesNotExist.new(new_resource.name, :disable)
      end

      if current_resource.enabled?
        converge_by("Disable #{new_resource}") do
          executor.execute!('disable-job', new_resource.name)
        end
      else
        Chef::Log.debug("#{new_resource} disabled - skipping")
      end
    end

    #
    # Enable an existing Jenkins job. After some careful discussions
    # internally, it was decided that raising an exception when the job
    # does not exist is the best developer experience.
    #
    # @raise [JobDoesNotExist]
    #   if the job does not exist
    #
    def action_enable
      unless current_resource.exists?
        raise JobDoesNotExist.new(new_resource.name, :enable)
      end

      if current_resource.enabled?
        Chef::Log.debug("#{new_resource} enabled - skipping")
      else
        converge_by("Enable #{new_resource}") do
          executor.execute!('enable-job', new_resource.name)
        end
      end
    end

    private

    #
    # The job in the current, in XML format.
    #
    # @return [nil, Hash]
    #   nil if the job does not exist, or a hash of important information if
    #   it does
    #
    def current_job
      return @current_job if @current_job

      Chef::Log.debug "Load #{new_resource} job information"

      response = executor.execute('get-job', new_resource.name)
      return nil if response.nil? || response =~ /No such job/

      Chef::Log.debug "Parse #{new_resource} as XML"
      xml = REXML::Document.new(response)
      disabled = xml.elements['//disabled']

      @current_job = {
        enabled: disabled.text == 'false',
        xml:     xml,
        raw:     response,
      }
      @current_job
    end

    #
    # Helper method for determining if the given JSON is in sync with the
    # current configuration on the Jenkins server.
    #
    # We have to create REXML objects and then remove any whitespace because
    # XML is evil and sometimes sucks at the simplest things, like comparing
    # itself.
    #
    # @return [Boolean]
    #
    def has_correct_config?
      current = StringIO.new
      wanted  = StringIO.new

      current_job[:xml].write(current, 2)
      REXML::Document.new(::File.read(new_resource.config)).write(wanted, 2)

      current.string == wanted.string
    end

    #
    # Validate that a configuration file was given as a parameter to the
    # resource. This method also validates the given config file path exists
    # on the target node. Finally, this method reads the contents of the file
    # and verifies it is valid XML.
    #
    def validate_config!
      Chef::Log.debug "Validate #{new_resource} configuration"

      if new_resource.config.nil?
        fail("#{new_resource} must specify a configuration file!")
      elsif !::File.exists?(new_resource.config)
        fail("#{new_resource} config `#{new_resource.config}` does not exist!")
      else
        begin
          REXML::Document.new(::File.read(new_resource.config))
        rescue REXML::ParseException
          fail("#{new_resource} config `#{new_resource.config}` is not valid XML!")
        end
      end
    end
  end
end