class CreateCandidateDocumentsAndHistoryTables < ActiveRecord::Migration[8.1]
  def change
    create_table :candidate_documents do |t|
      t.references :candidate_profile, null: false, foreign_key: true
      t.string :document_type, null: false, default: "cv"
      t.string :original_filename
      t.string :content_type
      t.bigint :file_size
      t.integer :parsing_status, null: false, default: 0
      t.jsonb :parsed_data, null: false, default: {}
      t.datetime :parsed_at
      t.string :failure_reason
      t.timestamps
    end
    add_index :candidate_documents, :parsing_status

    create_table :educations do |t|
      t.references :candidate_profile, null: false, foreign_key: true
      t.string :institution
      t.string :study
      t.string :location
      t.string :level
      t.date :start_date
      t.date :end_date
      t.integer :position, null: false, default: 0
      t.timestamps
    end

    create_table :work_experiences do |t|
      t.references :candidate_profile, null: false, foreign_key: true
      t.string :job_title
      t.string :company_name
      t.text :responsibilities
      t.date :start_date
      t.date :end_date
      t.boolean :current_job, null: false, default: false
      t.integer :position, null: false, default: 0
      t.timestamps
    end
  end
end
