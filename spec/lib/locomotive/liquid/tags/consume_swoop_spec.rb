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

  context '#rendering' do

    it 'puts the response into the liquid variable' do
      pending "disabled"

      response = mock('response', code: 200, parsed_response: parsed_response('title' => 'Locomotive rocks !'))
      Locomotive::Httparty::Webservice.stubs(:get).returns(response)
      template = "{% consume_swoop blog from \"http://blog.locomotiveapp.org/api/read\" %}{{ blog.title }}{% endconsume %}"
      Liquid::Template.parse(template).render.should == 'Locomotive rocks !'
    end

    it 'puts the response into the liquid variable using a url from a variable' do
      pending "disabled"

      response = mock('response', code: 200, parsed_response: parsed_response('title' => 'Locomotive rocks !'))
      Locomotive::Httparty::Webservice.stubs(:get).returns(response)
      template = "{% consume_swoop blog from url %}{{ blog.title }}{% endconsume %}"
      Liquid::Template.parse(template).render('url' => "http://blog.locomotiveapp.org/api/read").should == 'Locomotive rocks !'
    end

    it 'puts the response into the liquid variable using a url from a variable that changes within an iteration' do
      pending "disabled"

      base_uri = 'http://blog.locomotiveapp.org'
      template = "{% consume_swoop blog from url %}{{ blog.title }}{% endconsume %}"
      compiled_template = Liquid::Template.parse(template)

      [['/api/read', 'Locomotive rocks !'], ['/api/read_again', 'Locomotive still rocks !']].each do |path, title|
        response = mock('response', code: 200, parsed_response: parsed_response('title' => title))
        Locomotive::Httparty::Webservice.stubs(:get).with(path, {:base_uri => base_uri}).returns(response)
        compiled_template.render('url' => base_uri + path).should == title
      end
    end
  end

  context 'timeout' do

    before(:each) do
      @url = 'http://blog.locomotiveapp.org/api/read'
      @template = %{{% consume_swoop blog from "#{@url}" timeout:5 %}{{ blog.title }}{% endconsume_swoop %}}
    end

    it 'should pass the timeout option to httparty' do
      pending "disabled"

      Locomotive::Httparty::Webservice.expects(:consume).with(@url, {timeout: 5.0})
      Liquid::Template.parse(@template).render
    end

    it 'should return the previous successful response if a timeout occurs' do
      pending "disabled"

      Locomotive::Httparty::Webservice.stubs(:consume).returns({ 'title' => 'first response' })
      template = Liquid::Template.parse(@template)

      template.render.should == 'first response'

      Locomotive::Httparty::Webservice.stubs(:consume).raises(Timeout::Error)
      template.render.should == 'first response'
    end

  end

  def parsed_response(attributes)
    OpenStruct.new(underscore_keys: attributes)
  end
end
