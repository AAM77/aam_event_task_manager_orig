class Task < ApplicationRecord
  belongs_to :event
  has_many :user_tasks, dependent: :destroy
  has_many :users, through: :user_tasks

  validates_presence_of :name, message: "The task name cannot be blank"
  validates_uniqueness_of :name, case_sensitive: false, scope: :event_id, message: "You already have a task with that name in this event."
  validate :deadline_date_cannot_be_in_the_past
  validates :users, length: {
    maximum: :max_participants,
    message: "The task can have only #{:max_participants} number of participants."
  }

  before_validation :set_defaults
  before_create :capitalize_name
  after_create :assign_admin

  scope :group_tasks, -> { where(group_task: true) }
  scope :solo_tasks, -> { where(group_task: false) }
  scope :not_complete, -> { where("admin_confirmed_completion_at IS NULL") }
  scope :admin_marked_complete, -> { where("admin_confirmed_completion_at IS NOT NULL") }

  ####################################################
  # Adds: conditions for validation & custom message #
  # Makes sure that the date has not already passed  #
  ####################################################
  def deadline_date_cannot_be_in_the_past
    errors.add(:deadline_date, "The deadline date cannot be in the past!") if
      deadline_date and deadline_date < Date.today
  end

  ######################
  # Capitalizes the Name #
  ######################
  def capitalize_name
    self.name = self.name.capitalize
  end

  ##################################################################
  # sets the max_participants for a solo_task to 1                 #
  # even if a user manages to insert a different value             #
  # into the field for number of max people allowed to participate #
  ##################################################################
  def set_defaults
    unless self.group_task
      self.max_participants = 1
    end
  end

  #############################################
  # Assigns the admin to be same as the event #
  #############################################

  def assign_admin
    event = Event.find(self.event_id)
    self.admin_id = event.admin_id
    self.save
  end

  ###########################
  # Checks if user id admin #
  ###########################
  def task_admin(user)
    self.admin_id == user.id
  end

  #################################
  # Checks if user already exists #
  #################################
  def detect_user?(participant)
    self.users.where(id: participant.id).first
  end

  #########################
  # Adds a user to a task #
  #########################
  def add_participant(participant)
    event = Event.find(self.event_id)

    if self.task_type == "Group Task" # || (self.task_type == "Solo Task" && self.users.size != 1)
      self.users << participant
    elsif self.task_type == "Solo Task" && self.users.size != 1
      self.users << participant
    end

    participant.events << event unless participant.event_ids.include?(event_id)

    self.save
    participant.save
  end

  ##############################
  # Removes a user from a task #
  ##############################
  def remove_participant(participant)
    user_task = UserTask.find_by_user_id_and_task_id(participant.id, self.id)
    user_task.delete if user_task

    event = Event.find(self.event_id)
    event.remove_from_event(participant)
  end

  ##########################################################
  # Lists the usernames of users participating in the task #
  ##########################################################
  def list_participants
    list = self.users
    if list.size == 1
      list.first.username
    else
      list.map { |u| u.username.capitalize }.join(", ")
    end
  end

  ######################
  # Labels a task type #
  ######################
  def task_type
    self.group_task ? "Group Task" : "Solo Task"
  end

  ########################################################################################
  # determines how many points each user should get                                      #
  # I am choosing this method of point distribution to make it fair                      #
  # if a single user completes a group task, why shouldn't that person earn more points? #
  ########################################################################################
  def points_distributed_to_each_participant
    points = (self.points_awarded.to_f / self.users.size).round(3)
  end

  ##############################################################
  # handles the distribution of the points to each participant #
  ##############################################################
  def distribute_points
    self.users.each do |user|
      total_points = user.total_points.to_f + points_distributed_to_each_participant.to_f
      total_points = total_points.round(4)
      user.update(total_points: total_points)
    end
  end

end
