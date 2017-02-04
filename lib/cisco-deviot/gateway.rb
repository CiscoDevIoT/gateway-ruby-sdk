# Copyright 2015 Cisco Systems, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.

require 'json'
require 'logger'
require 'net/http'
require 'uri'
require 'cisco-deviot/mqtt-connector'
require 'cisco-deviot/thing'

MODE_HTTP_PULL = 0
MODE_HTTP_PUSH = 1
MODE_MQTT = 2

class Gateway
  @@logger = Logger.new(STDOUT)
  @@logger.datetime_format = '%Y-%m-%d %H:%M:%S'

  attr_reader :name
  attr_reader :owner

  def initialize(name, deviot_server, mqtt_server, account = '', kind = 'device')
    @name = name
    @owner = account
    @kind = kind
    @mode = MODE_MQTT
    @deviot_server = deviot_server
    @things = Hash.new
    @connector = MqttConnector.new(self, mqtt_server)
    @host = @connector.host
    @port = @connector.port
    @data = @connector.data
    @action = @connector.action
    @registration_started = FALSE
  end

  def start
    if @registration_started
      @@logger.warn("gateway service #{@name} already started")
    else
      @registration_started = TRUE

      Thread.new {
        registered_ok = 0
        while @registration_started
          begin
            uri = URI.parse(@deviot_server)
            http = Net::HTTP.new(uri.host, uri.port)
            http.read_timeout = 10
            http.open_timeout = 10
            request = Net::HTTP::Post.new('/api/v1/gateways', {'Content-Type': 'application/json'})
            request.body = {name: @name, kind: @kind, owner: @owner,
                            host: @host, port: @port, mode: @mode,
                            data: @data, action: @action,
                            sensors: @things.values.collect{|x| x.get_model}}.to_json
            response = http.request(request)
            if response.code.to_i < 300
              if registered_ok != 2
                @@logger.info("gateway service #{@name} registered to #{@deviot_server}")
              end
              registered_ok = 2
            else
              if registered_ok != 1
                @@logger.error("failed to register gateway #{@name} to #{@deviot_server}: #{response.code}")
              end
              registered_ok = 1
            end
          rescue StandardError => e
            if registered_ok != 1
              @@logger.error("failed to register gateway #{@name} to #{@deviot_server}: #{e}")
            end
            registered_ok = 1
          end
          sleep(100)
        end
      }
      @connector.start
      @@logger.info("gateway service #{@name} started")
    end
  end

  def stop
    if @registration_started
      @connector.stop
      @registration_started = FALSE
      @@logger.error("gateway service #{@name} stopped")
    else
      @@logger.warn("gateway service #{@name} already stopped")
    end
  end

  def register(thing)
    unless thing.is_a?(Thing)
      raise ArgumentError.new("#{thing} is not a thing")
    end
    if @things.has_key?(thing.id)
      @@logger.warn("thing #{thing} is already registered")
    else
      @things.store(thing.id, thing)
      @@logger.info("thing #{thing} registered")
    end
  end

  def unregister(thing)
    if @things.has_key?(thing.id)
      @things.delete(thing.id)
      @@logger.info("thing #{thing} is unregistered")
    else
      @@logger.warn("thing #{thing} is not registered")
    end
  end

  def send_data(data)
    @connector.publish(data)
  end

  def call_action(data)
    name = data.delete('name')
    action = data.delete('action')
    if name && action && @things.has_key?(name)
      thing = @things[name]
      action_model = thing.actions.find{|a| a.name == action}
      if thing.respond_to?(action) && action_model
        args = action_model.parameters.collect{|x| data[x.name]}
        if action_model.need_payload
          args.push(delete('payload'))
        end
        thing.send(action, *args)
        @@logger.info("#{thing} called with #{action}(#{data})")
      else
        raise ArgumentError.new("no action #{action} defined in thing #{thing}")
      end
    else
      raise ArgumentError.new("thing #{name} is not registered")
    end
  end
end
