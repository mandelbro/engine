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
      pending "disabled"

      markup = 'event from "events" username: "john", password: "easyone"'
      lambda do
        Locomotive::Liquid::Tags::ConsumeSwoop.new('consume_swoop', markup, ["{% endconsume_swoop %}"], {})
      end.should_not raise_error
    end

    it 'should parse the correct url with complex syntax with attributes' do
      pending "disabled"

      markup = 'blog from "http://www.locomotiveapp.org" username: "john", password: "easyone"'
      tag = Locomotive::Liquid::Tags::ConsumeSwoop.new('consume_swoop', markup, ["{% endconsume_swoop %}"], {})
      tag.instance_variable_get(:@url).should == "http://www.locomotiveapp.org"
    end

    it 'raises an error if the syntax is incorrect' do
      markup = 'blog http://www.locomotiveapp.org'
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
