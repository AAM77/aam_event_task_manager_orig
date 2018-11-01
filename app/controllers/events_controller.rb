class EventsController < ApplicationController
  before_action :redirect_if_not_logged_in
  before_action :event_exists?, only: [:show, :edit, :update, :destroy, :show_admin]
  before_action :set_event, only: [:show, :edit, :update, :destroy, :show_admin]

  ###########################################
  # handles routing to a list of all events #
  ###########################################
  def index
    @events = Event.all.order(:name)
  end

  ##############################################
  # handles routing to form to create an event #
  ##############################################
  def new
    @event = Event.new
  end

  ####################################
  # handles the creation of an event #
  ####################################
  def create
    @event = Event.new(event_params)
    @event.admin_id = current_user.id

    if @event.save
      redirect_to show_admin_event_path(@event)
    else
      redirect_to new_event_path
      flash[:warning] = @event.errors.messages[:name].first
    end
  end

  ###########################################
  # handles routing to an event's show page #
  ###########################################
  def show
    @incomplete_ordered_tasks = @event.order_tasks.not_complete
    @complete_ordered_tasks = @event.order_tasks.admin_marked_complete
    @task = Task.new
    @admin = User.find(@event.admin_id)
  end

  ############################################
  # handles routing to form to edit an event #
  ############################################
  def edit
  end

  #############################
  # handles updating an event #
  #############################
  def update
    @event.update(event_params)
    redirect_to show_admin_event_path(@event)
  end

  #############################
  # handles deleting an event #
  #############################
  def destroy
    event_name = @event.name
    Event.destroy(@event.id)
    redirect_to user_path(current_user)
    flash[:warning] = "You deleted the event: #{event_name}."
  end

  ############################################
  # handles routing to the admin's show page #
  ############################################
  def show_admin
    if @event.admin_id != current_user.id
      redirect_to event_path(@event)
      flash[:warning] = "Hey, stop it! You aren't this event's admin!"
    else
      @incomplete_ordered_tasks = @event.order_tasks.not_complete
      @complete_ordered_tasks = @event.order_tasks.admin_marked_complete
      @task = Task.new
    end
  end

  private
    ########################
    # finds an event by id #
    ########################
    def set_event
      @event = Event.find_by(id: params[:id])
    end

    def event_exists?
      unless set_event
        redirect_to events_path
        flash[:warning] = "That event does not exist"
      end
    end

    def event_params
      params.require(:event).permit(:name, :deadline_date, :deadline_time, :admin_id)
    end

end
