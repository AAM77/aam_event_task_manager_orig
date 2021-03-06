class CreateTasks < ActiveRecord::Migration[5.2]
  def change
    create_table :tasks do |t|
      t.string :name
      t.decimal :points_awarded, default: 0.00, precision: 30, scale: 2
      t.integer :event_id, index: true
      t.integer :admin_id
      t.date :deadline_date
      t.time :deadline_time
      t.integer :max_participants, default: 1
      t.boolean :group_task, default: false
      t.datetime :user_completed_at
      t.datetime :admin_confirmed_completion_at
      t.boolean :completed

      t.timestamps
    end
  end
end

#note: if both user_complete & admin_complete are true, the user gets the points added to total.
