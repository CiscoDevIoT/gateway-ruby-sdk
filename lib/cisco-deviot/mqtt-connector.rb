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
require 'mqtt'
require 'logger'


class MqttConnector
  @@logger = Logger.new(STDOUT)
  @@logger.datetime_format = '%Y-%m-%d %H:%M:%S'

  attr_reader :host
  attr_reader :port
  attr_reader :data
  attr_reader :action

  def initialize(gateway, mqtt_server)
    uri = URI.parse(mqtt_server)
    @gateway = gateway
    @host  = uri.host
    @port = uri.port ? uri.port : 1883
    ns = gateway.owner ? gateway.owner.gsub('@', '_') : '_'
    name = gateway.name.gsub('/', '_')
    @data = "/deviot/#{ns}/#{name}/data"
    @action = "/deviot/#{ns}/#{name}/action"
    @action_thread = nil
  end

  def start
    @action_thread = Thread.new {
      @seconds = 2
      while true
        begin
          MQTT::Client.connect({host: @host, port: @port}) { |client|
            @@logger.info("mqtt server #{self} connected")
            @seconds = 2
            @client = client
            client.get(@action) do |topic, message|
              begin
                @gateway.call_action(JSON.parse(message))
              rescue Exception => e
                @@logger.error("failed to call action #{message}: #{e}")
              end
            end
          }
        rescue Exception => e
          @client = nil
          @@logger.error("mqtt server #{self} disconnected, reconnect in #{@seconds} seconds...")
          sleep(@seconds)
          @seconds = [128, @seconds * 2].min
        end
      end
    }
  end

  def stop
    if @client
      @client.unsubscribe(@action)
      @action_thread.kill if @action_thread and @action_thread.alive?
      @action_thread = nil
      @client.disconnect
      @client = nil
      @@logger.info("mqtt server #{self} disconnected")
    end
  end

  def publish(data)
    if @client
      begin
        @client.publish(@data, data.to_json)
      rescue Exception => e
        @@logger.error("failed to publish #{data}: #{e}")
      end
    end
  end

  def to_s
    "#{@host}:#{@port}"
  end
end
