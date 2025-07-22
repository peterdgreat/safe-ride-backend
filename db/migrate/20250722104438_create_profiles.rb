class CreateProfiles < ActiveRecord::Migration[8.0]
  def change
    create_table :profiles, id: :uuid do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.string :first_name
      t.string :last_name
      t.date :date_of_birth
      t.string :gender
      t.string :profile_picture_url

      t.timestamps
    end
  end
end
