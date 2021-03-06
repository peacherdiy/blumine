require 'test_helper'

class UserTest < ActiveSupport::TestCase
  def setup
    @user = users(:daqing)
    @issue = issues(:bug_report)
  end

  test "should not create user when name or email is empty" do
    user = User.new
    assert ! user.valid?

    user.name = "daqing"
    assert ! user.valid?
  end

  test "should provide valid email address" do
    user = User.new(:name => "daqing", :email => "abc", :password => "pop", :password_confirmation => "pop")
    assert ! user.valid?
  end

  test "emails should be unique" do
    another_user = User.new({:name => "another", :email => @user.email, :password => "another_user", :password_confirmation => "another_user"})
    assert ! another_user.valid?
  end

  test "password should be confirmed" do
    user = User.new(:name => "daqing", :email => "daqing1986@gmail.com", :password => "daqing")
    assert ! user.valid?

    user.password_confirmation = "foobar"
    assert ! user.valid?
  end

  test "create user" do
    user = User.new(:name => "daqing", :email => "daqing1986@gmail.com", :password => "daqing", :password_confirmation => "daqing")
    assert user.valid?
    assert ! user.salt.blank?
    assert ! user.encrypted_password.blank?
  end

  test "only creator of an issue or PM can assign issues" do
    assert @user.can_assign_issue?(@issue)

    another = users(:two)
    another.role = 'ProjectManager'
    assert another.can_assign_issue?(@issue)

    another.role = 'Developer'
    assert ! another.can_assign_issue?(@issue)
  end

  test "should not change state before the issue is assigned" do
    @issue.assigned_user = nil
    assert ! @user.can_change_state?(@issue)

    @user.role = 'ProjectManager'
    assert ! @user.can_change_state?(@issue)
  end

  test "only creator of an issue, PM or assigned user can change issue state after the issue is assigned" do
    @issue.assigned_user = users(:daqing)

    another = users(:two)
    another.role = 'ProjectManager'
    assert another.can_change_state?(@issue)

    another.role = 'Developer'
    assert ! another.can_change_state?(@issue)

    @issue.assigned_user = another
    assert another.can_change_state?(@issue)
  end

  test "only assinged user can manage todo items" do
    two = users(:two)
    @issue.assigned_user = @user
    assert ! two.can_manage_todo?(@issue)

    @issue.assigned_user = two
    assert two.can_manage_todo?(@issue)

    @issue.close!
    assert ! two.can_manage_todo?(@issue)
  end

  test "only issue creator can manage issue when issue's not closed" do
    @issue.work_on!
    assert @user.can_manage_issue?(@issue)
    assert ! users(:two).can_manage_issue?(@issue)

    @issue.mark_finished!
    @issue.close!
    assert ! @user.can_manage_issue?(@issue)
  end

  test "only creator can manage comments when the related issue is not closed" do
    comment = comments(:need_fix)
    issue = comment.issue
    issue.work_on!
    assert @user.can_manage_comment?(comment)

    issue.mark_finished!
    issue.close!
    assert ! @user.can_manage_comment?(comment)
  end
end
