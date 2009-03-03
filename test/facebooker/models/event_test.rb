require File.expand_path(File.dirname(__FILE__) + '/../../test_helper')

class Facebooker::EventTest < Test::Unit::TestCase
  def test_attendance_will_query_for_event_when_asked_for_full_event_object
    session = flexmock("a session object")
    eid = 123
    attendance = Facebooker::Event::Attendance.new
    attendance.eid = eid
    attendance.session = session
    event = Facebooker::Event.new
    event.eid = eid
    session.should_receive(:post).once.with('facebook.events.get', :eids => [eid]).and_return([{:eid => eid}])    
    assert_equal(123, attendance.event.eid)
  end
end