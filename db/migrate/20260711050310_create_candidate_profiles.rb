class CreateCandidateProfiles < ActiveRecord::Migration[8.1]
  def change
    create_table :candidate_profiles do |t|
      t.references :user, null: true, foreign_key: true
      t.references :job_function, null: true, foreign_key: true

      t.string :first_name
      t.string :last_name
      t.string :email
      t.string :phone
      t.string :city
      t.string :country, default: "Netherlands"

      t.integer :max_travel_time
      t.integer :search_status, null: false, default: 0
      t.text :reason_for_looking
      t.string :transport_modes, array: true, default: []

      t.integer :desired_salary
      t.integer :desired_percentage
      t.integer :average_daily_revenue
      t.integer :big_status
      t.string :big_number
      t.integer :years_experience

      t.date :available_from
      t.string :notice_period
      t.string :working_days, array: true, default: []

      t.text :motivation
      t.text :professional_summary
      t.text :internal_notes
      t.text :suggested_skills

      t.jsonb :field_provenance, null: false, default: {}
      t.datetime :prefilled_at
      t.datetime :consent_accepted_at
      t.boolean :duplicate_email, null: false, default: false
      t.integer :status, null: false, default: 0
      t.datetime :completed_at

      t.timestamps
    end
    add_index :candidate_profiles, :email
    add_index :candidate_profiles, :status
  end
end
