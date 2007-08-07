require File.dirname(__FILE__) + '/test_helper.rb'

class TestFacebooker < Test::Unit::TestCase
  
  class ComplexThing
    include Facebooker::Model
    attr_accessor :weight, :height
  end
  
  class Thing
    include Facebooker::Model
    attr_accessor :name, :job
    hash_settable_accessor :complex_thing, ComplexThing
    hash_settable_list_accessor :list_of_complex_things, ComplexThing
  end

  
  def test_can_instantiate_an_object_with_a_hash
    h = {:name => "Blob", :job => "Monster"}
    assert_equal("Blob", Thing.from_hash(h).name)
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
  
end

