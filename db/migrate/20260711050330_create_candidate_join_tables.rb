class CreateCandidateJoinTables < ActiveRecord::Migration[8.1]
  def change
    create_table :candidate_skills do |t|
      t.references :candidate_profile, null: false, foreign_key: true
      t.references :skill, null: false, foreign_key: true
      t.timestamps
    end
    add_index :candidate_skills, [ :candidate_profile_id, :skill_id ], unique: true

    create_table :candidate_languages do |t|
      t.references :candidate_profile, null: false, foreign_key: true
      t.references :language, null: false, foreign_key: true
      t.string :level
      t.timestamps
    end
    add_index :candidate_languages, [ :candidate_profile_id, :language_id ]

    create_table :candidate_regions do |t|
      t.references :candidate_profile, null: false, foreign_key: true
      t.references :region, null: false, foreign_key: true
      t.timestamps
    end
    add_index :candidate_regions, [ :candidate_profile_id, :region_id ], unique: true

    create_table :candidate_employment_types do |t|
      t.references :candidate_profile, null: false, foreign_key: true
      t.references :employment_type, null: false, foreign_key: true
      t.timestamps
    end
    add_index :candidate_employment_types, [ :candidate_profile_id, :employment_type_id ], unique: true,
              name: "index_candidate_employment_types_uniqueness"
  end
end
