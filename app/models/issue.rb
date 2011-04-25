# == Schema Information
# Schema version: 20110416033800
#
# Table name: issues
#
#  id             :integer         not null, primary key
#  project_id     :integer
#  title          :string(255)
#  content        :text
#  workflow_state :string(255)
#  created_at     :datetime
#  updated_at     :datetime
#  user_id        :integer
#

class Issue < ActiveRecord::Base
  include Workflow

  @@state_names = {
    :open => I18n.t('issue.state.open'),
    :working_on => I18n.t('issue.state.working_on'),
    :finished => I18n.t('issue.state.finished'),
    :closed => I18n.t('issue.state.closed'),
    :invalid => I18n.t('issue.state.invalid'),
    :ignored => I18n.t('issue.state.ignored'),
    :reopened => I18n.t('issue.state.reopened')
  }

  @@event_names = {
    :work_on => I18n.t('issue.event.work_on'),
    :mark_invalid => I18n.t('issue.event.mark_invalid'),
    :ignore => I18n.t('issue.event.ignore'),
    :mark_finished =>I18n.t('issue.event.mark_finished'),
    :reopen => I18n.t('issue.event.reopen'),
    :continue => I18n.t('issue.event.continue'),
    :close => I18n.t('issue.event.close'),
  }

  workflow do
    state :open do
      event :work_on, :transitions_to => :working_on
      event :mark_invalid, :transitions_to => :invalid
      event :ignore, :transitions_to => :ignored
      event :close, :transitions_to => :closed
    end

    state :working_on do
      event :mark_finished, :transitions_to => :finished
    end

    state :finished do
      event :continue, :transitions_to => :working_on
      event :close, :transitions_to => :closed
    end

    state :invalid do
      event :reopen, :transitions_to => :reopened
    end

    state :closed do
      event :reopen, :transitions_to => :reopened
    end

    state :ignored do
      event :reopen, :transitions_to => :reopened
    end

    state :reopened do
      event :work_on, :transitions_to => :working_on
    end
  end

  belongs_to :project
  belongs_to :user

  has_many :comments
  has_many :todo_items

  has_one :issue_assignment
  has_one :assigned_user, :through => :issue_assignment, :source => :user

  before_validation :set_default_content

  validates :title, :content, :presence => true
  validates :user_id, :project_id, :presence => true

  def self.state_name(state_sym)
    @@state_names[state_sym]
  end

  def self.event_name(event_sym)
    @@event_names[event_sym]
  end

  def self.valid_state?(state_sym)
    self.workflow_spec.states.keys.member? state_sym
  end

  def current_state_name
    Issue.state_name(self.current_state.name)
  end

  def default_content
    "记录在Todo里。"
  end

  class << self
    Issue.workflow_spec.states.keys.each do |state_sym|
      define_method("state_#{state_sym.to_s}") do
        where(:workflow_state => state_sym)
      end

      define_method("except_#{state_sym.to_s}") do
        where(["workflow_state != ?", state_sym.to_s])
      end
    end
  end

  private
    def set_default_content
      self.content = default_content if self.content.blank?
    end
end
