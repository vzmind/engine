Given %r{^I have an? "([^"]*)" model which has many "([^"]*)"$} do |parent_model, child_model|
  @parent_model = FactoryGirl.build(:content_type, :site => @site, :name => parent_model).tap do |ct|
    ct.content_custom_fields.build :label => 'Body', :kind => 'string', :required => false
    ct.save!
  end
  @child_model = FactoryGirl.build(:content_type, :site => @site, :name => child_model).tap do |ct|
    ct.content_custom_fields.build :label => 'Body', :kind => 'string', :required => false
    ct.content_custom_fields.build :label => parent_model.singularize, :kind => 'has_one', :required => false, :target => parent_model
    ct.save!
  end

  @parent_model.content_custom_fields.build({
    :label          => child_model,
    :kind           => 'has_many',
    :target         => @child_model.content_klass.to_s,
    :reverse_lookup => @child_model.content_klass.custom_field_alias_to_name(parent_model.downcase.singularize)
  })
end

Then /^I should be able to view a paginated list of "([^"]*)" per "([^"]*)"$/ do |parent_model, child_model|
  # Create contents
  @parent_model.contents.create!(:slug => 'parent', :body => 'Parent')
  @child_model.contents.create!(:slug => 'one', :body => 'One')
  @child_model.contents.create!(:slug => 'two', :body => 'Two')
  @child_model.contents.create!(:slug => 'three', :body => 'Three')

  # Create a page
  raw_template = %{
  {% for article in contents.articles %}
    {% paginate article.comments by 2 %}
      {% for comment in paginate.collection %}
        {{ comment.body }}
      {% endfor %}
      {{ paginate | default_pagination }}
    {% endpaginate %}
  {% endfor %}
  }

  # Create a page
  FactoryGirl.create(:page, :site => @site, :slug => 'hello', :raw_template => raw_template)

  # The page should have the first two comments
  visit '/hello'
  page.should have_content 'one'
  page.should have_content 'two'
  page.should_not have_content 'three'
end