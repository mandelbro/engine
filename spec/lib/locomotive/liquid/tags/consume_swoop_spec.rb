require 'spec_helper'

def make_tag(markup)
  Locomotive::Liquid::Tags::ConsumeSwoop.new('consume_swoop', markup, ["{% endconsume_swoop %}"], {})
end

describe Locomotive::Liquid::Tags::ConsumeSwoop do

  context '#validating syntax' do

    it 'validates a basic syntax' do
      markup = 'events from "events"'
      lambda do
        Locomotive::Liquid::Tags::ConsumeSwoop.new('consume_swoop', markup, ["{% endconsume_swoop %}"], {})
      end.should_not raise_error
    end

    it 'builds a SWOOP URL from events API endpoint shorthand' do
      markup = 'event from "events"'
      tag = make_tag(markup)
      tag.instance_variable_get(:@url).should == "https://swoop.up.co/events"

    end

    it 'builds a SWOOP URL from people API endpoint shorthand' do
      markup = 'people from "people"'
      tag = make_tag(markup)
      tag.instance_variable_get(:@url).should == "https://swoop.up.co/people"
    end

    it 'passes normal URLs through untouched' do
      markup = 'posts from "http://blog.up.co/feed/json"'
      tag = make_tag(markup)
      tag.instance_variable_get(:@url).should == "http://blog.up.co/feed/json"
    end

    it 'validates more complex syntax with attributes' do
      markup = 'event from "events" username: "john", password: "easyone"'
      lambda do
        Locomotive::Liquid::Tags::ConsumeSwoop.new('consume_swoop', markup, ["{% endconsume_swoop %}"], {})
      end.should_not raise_error
    end

    it 'adds swoop event search terms into the query object' do
      markup =
        'event from "events" city: "Seattle", event_type: "Startup Weekend", timeout: 30'
      tag = make_tag(markup)

      options = tag.instance_variable_get(:@options)
      options.keys.should include("query")

      options['query'].keys.should include("city")
      options['query'].keys.should include("event_type")

      options['query']['city'].should == "Seattle"
      options['query']['event_type'].should == "Startup Weekend"
    end

    it 'adds swoop people search terms into the query object' do
      markup =
        'event from "people" roles: "Core Team", timeout: 30'
      tag = make_tag(markup)

      options = tag.instance_variable_get(:@options)
      options.keys.should include("query")

      options['query'].keys.should include("roles")

      options['query']['roles'].should == "Core Team"
    end

    it 'does not add non-swoop search terms to the query object' do
      markup =
        'event from "events" city: "Seattle", event_type: "Startup Weekend", timeout: 30'
      tag = make_tag(markup)

      options = tag.instance_variable_get(:@options)
      options.keys.should include("query")
      options.keys.should include("timeout")

      options['query'].keys.should include("city")
      options['query'].keys.should_not include("timeout")
    end

    it 'should parse the correct url with complex syntax with attributes' do
      markup = 'events from "events" event_type: "Startup Weekend", city: "Seattle"'
      tag = Locomotive::Liquid::Tags::ConsumeSwoop.new('consume_swoop', markup, ["{% endconsume_swoop %}"], {})
      tag.instance_variable_get(:@url).should == "https://swoop.up.co/events"
    end

    it 'raises an error if the syntax is incorrect' do
      markup = 'events http://swoop.up.co'
      lambda do
        Locomotive::Liquid::Tags::ConsumeSwoop.new('consume_swoop', markup, ["{% endconsume_swoop %}"], {})
      end.should raise_error
    end

  end

  def parsed_response(attributes)
    OpenStruct.new(underscore_keys: attributes)
  end

  context 'configuring the tag' do
    before(:each) do
      @prev_env_val = ENV['SWOOP_URL']
    end

    after(:each) do
      ENV['SWOOP_URL'] = @prev_env_val
    end

    it 'should pull swoop base url from environment if available' do
      new_base = 'http://sw-swoop.herokuapp.com'
      ENV['SWOOP_URL'] = new_base
      tag = make_tag("events from 'events'")
      tag.instance_variable_get(:@swoop_base).should == new_base
    end

    it 'should default to https://swoop.up.co' do
      tag = make_tag("events from 'events'")
      tag.instance_variable_get(:@swoop_base).should == 'https://swoop.up.co'
    end
  end

  context 'basic authentication' do
    before(:each) do
      @prev_swoop_user = ENV['SWOOP_USER']
      @prev_swoop_pass = ENV['SWOOP_PASS']
    end

    after(:each) do
      ENV['SWOOP_USER'] = @prev_swoop_user
      ENV['SWOOP_PASS'] = @prev_swoop_pass
    end

    it 'should automatically add username and password to options' do
      ENV['SWOOP_USER'] = 'user'
      ENV['SWOOP_PASS'] = 'pass'
      tag = make_tag("events from 'events'")

      tag.instance_variable_get(:@swoop_user).should == 'user'
      tag.instance_variable_get(:@swoop_pass).should == 'pass'
    end
  end
end
