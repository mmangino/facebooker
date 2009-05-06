require File.expand_path(File.dirname(__FILE__) + '/../test_helper')

class Facebooker::ModelTest < Test::Unit::TestCase
  
  class ComplexThing
    include Facebooker::Model
    attr_accessor :weight, :height
  end
  
  class Thing
    include Facebooker::Model
    attr_accessor :name, :job
    hash_settable_accessor :complex_thing, ComplexThing
    hash_settable_list_accessor :list_of_complex_things, ComplexThing

    def initialize *args
      @session = nil
      super
    end
  end

  class PopulatingThing
    include Facebooker::Model
    populating_attr_accessor :first_name

    def initialize
      @first_name = nil
      @populated  = false
    end
  end
  
  def test_can_instantiate_an_object_with_a_hash
    h = {:name => "Blob", :job => "Monster"}
    assert_equal("Blob", Thing.from_hash(h).name)
  end
  
  def test_ignores_non_model_keys
    h = {:name => "Blob", :job => "Monster", :not_there=>true}
    assert_equal("Blob", Thing.from_hash(h).name)    
  end
  
  def test_logs_non_model_keys
    flexmock(Facebooker::Logging).should_receive(:log_info)
    h = {:name => "Blob", :job => "Monster", :not_there=>true}
    Thing.from_hash(h)
  end
    
  
  def test_if_no_hash_is_given_to_model_constructor_no_attributes_are_set
    assert_nothing_raised {
      t = Thing.new
      assert_nil(t.name)
    }
  end
  
  def test_can_declare_hash_settable_attributes
    t = Thing.new({})
    t.complex_thing = {:weight => 123, :height => 5.4}
    assert_equal(123, t.complex_thing.weight)
    t.complex_thing = ComplexThing.new(:weight => 321)
    assert_equal(321, t.complex_thing.weight)
  end
  
  def test_can_declare_attributes_which_are_settable_via_a_list_of_hashes
    t = Thing.new
    t.list_of_complex_things = [{:weight => 444, :height => 123.0}, {:weight => 222, :height => 321.1}]
    assert_equal("123.0, 321.1", t.list_of_complex_things.map{|ct| ct.height.to_s}.sort.join(', '))
    t.list_of_complex_things = [ComplexThing.new(:weight => 555), ComplexThing.new(:weight => 111)]
    assert_equal("111, 555", t.list_of_complex_things.map{|ct| ct.weight.to_s}.sort.join(', '))
  end
  
  def test_if_you_try_to_use_a_models_session_without_initializing_it_first_you_get_a_descriptive_error
    t = Thing.new
    assert_raises(Facebooker::Model::UnboundSessionException) {
      t.session
    }
  end
  
  def test_populating_reader_will_call_populate_if_model_was_not_previously_populated
    t = PopulatingThing.new
    flexmock(t).should_receive(:populate).once
    t.first_name
  end
  
  def test_populating_reader_will_not_call_populate_if_model_was_previously_populated
    t = PopulatingThing.new
    flexmock(t).should_receive(:populated?).and_return(true)
    flexmock(t).should_receive(:populate).never
    t.first_name
  end
  
  def test_attempting_to_access_a_populating_reader_will_raise_an_exception_if_populate_was_not_defined
    t = PopulatingThing.new
    assert_raises(NotImplementedError) {
      t.first_name
    }
  end

  def test_populate_from_hash_e_should_call_a_setter_for_a_key
    t = PopulatingThing.new
    flexmock(t).should_receive('mykey=').with('a value')
    t.populate_from_hash!({ :mykey => 'a value' })
  end
  
  def test_populate_from_hash_e_should_call_a_setter_for_a_key_if_the_value_is_false
    t = PopulatingThing.new
    flexmock(t).should_receive('mykey=').with(false)
    t.populate_from_hash!({ :mykey => false })
  end

  def test_populate_from_hash_e_should_call_not_a_setter_for_a_key_if_the_value_is_nil
    t = PopulatingThing.new
    flexmock(t).should_receive('mykey=').never
    t.populate_from_hash!({ :mykey => nil })
  end

  def test_populate_from_hash_should_check_for_an_empty_hash
    t = PopulatingThing.new
    hash = {}
    flexmock(hash).should_receive('empty?')
    t.populate_from_hash!(hash)
  end

  def test_populate_from_hash_should_check_for_a_nil_param
    t = PopulatingThing.new
    hash = nil
    assert_nothing_raised do
      t.populate_from_hash!(hash)
    end
  end

end

