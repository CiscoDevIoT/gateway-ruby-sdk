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

PROPERTY_TYPE_INT = 0
PROPERTY_TYPE_STRING = 1
PROPERTY_TYPE_BOOL = 2
PROPERTY_TYPE_COLOR = 3

class Property
  attr_reader :name
  attr_reader :type
  attr_reader :value
  attr_reader :unit
  attr_reader :range
  attr_reader :description

  def initialize(name, type = PROPERTY_TYPE_INT, value = nil, unit = '', range = nil, description = '')
    @name = name
    @type = type
    @value = value
    @unit = unit
    @range = range
    @description = description
  end

  def default_value_for(type)
    case type
      when PROPERTY_TYPE_INT
        return 0
      when PROPERTY_TYPE_STRING
        return ''
      when PROPERTY_TYPE_BOOL
        return FALSE
      when PROPERTY_TYPE_COLOR
        return 'FFFFFF'
      else
        return nil
    end
  end

  def get_model
    {name: @name, type: @type, value: @value, range: @range,
     unit: @unit, description: @description}
  end
end

class Action
  attr_reader :name
  attr_reader :parameters
  attr_reader :need_payload

  def initialize(name, need_payload = false)
    @name = name
    @parameters = []
    @need_payload = need_payload
  end

  def add_parameter(parameter)
    if parameter.instance_of? String
      @parameters.push(Property.new(parameter))
      return self
    end
    if parameter.instance_of? Property
      @parameters.push(parameter)
      return self
    end
    raise ArgumentError
  end

  def get_model
    {name: @name, parameters: @parameters.collect {|p| p.get_model}}
  end
end

class Thing
  attr_reader :id
  attr_reader :name
  attr_reader :kind
  attr_reader :properties
  attr_reader :actions

  def initialize(id, name, kind)
    @id = id
    @name = name
    @kind = kind
    @properties = []
    @actions = []
  end

  def add_property(property)
    if property.instance_of? String
      @properties.push(Property.new(property))
      return self
    end
    if property.instance_of? Property
      @properties.push(property)
      return self
    end
    raise ArgumentError
  end

  def add_action(action)
    if action.instance_of? String
      @actions.push(Property.new(action))
      return self
    end
    if action.instance_of? Action
      @actions.push(action)
      return self
    end
    raise ArgumentError
  end

  def to_s
    "#{@id}[#{@name}(#{@kind})]"
  end

  def get_model
    {id: @id, name: @name, kind: @kind, properties: @properties.collect {|p| p.get_model},
     actions: @actions.collect {|p| p.get_model}}
  end
end
