class CreateUsersAndReferenceTables < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :email, null: false
      t.string :first_name
      t.string :last_name
      t.timestamps
    end
    add_index :users, :email, unique: true

    create_table :job_functions do |t|
      t.string :name, null: false
      t.string :key, null: false
      t.boolean :requires_big, null: false, default: false
      t.boolean :requires_daily_revenue, null: false, default: false
      t.integer :position, null: false, default: 0
      t.timestamps
    end
    add_index :job_functions, :key, unique: true

    create_table :regions do |t|
      t.string :name, null: false
      t.string :code
      t.integer :position, null: false, default: 0
      t.timestamps
    end
    add_index :regions, :name, unique: true

    create_table :employment_types do |t|
      t.string :name, null: false
      t.string :key
      t.boolean :salary_based, null: false, default: false
      t.boolean :percentage_based, null: false, default: false
      t.integer :position, null: false, default: 0
      t.timestamps
    end
    add_index :employment_types, :key, unique: true

    create_table :languages do |t|
      t.string :name, null: false
      t.string :code
      t.integer :position, null: false, default: 0
      t.timestamps
    end
    add_index :languages, :code, unique: true

    create_table :skills do |t|
      t.references :job_function, null: false, foreign_key: true
      t.string :name, null: false
      t.integer :position, null: false, default: 0
      t.timestamps
    end
    add_index :skills, [ :job_function_id, :name ], unique: true
  end
end
