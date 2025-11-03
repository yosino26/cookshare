# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2025_11_02_223455) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "categories", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_categories_on_name", unique: true
  end

  create_table "comments", force: :cascade do |t|
    t.text "content"
    t.bigint "user_id", null: false
    t.bigint "recipe_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "hidden", default: false, null: false
    t.index ["created_at"], name: "index_comments_on_created_at"
    t.index ["hidden"], name: "index_comments_on_hidden"
    t.index ["recipe_id"], name: "index_comments_on_recipe_id"
    t.index ["user_id"], name: "index_comments_on_user_id"
  end

  create_table "favorites", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "recipe_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["recipe_id"], name: "index_favorites_on_recipe_id"
    t.index ["user_id", "recipe_id"], name: "idx_favorites_unique_user_recipe", unique: true
    t.index ["user_id", "recipe_id"], name: "index_favorites_on_user_id_and_recipe_id", unique: true
    t.index ["user_id"], name: "index_favorites_on_user_id"
  end

  create_table "follows", force: :cascade do |t|
    t.bigint "follower_id", null: false
    t.bigint "following_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["follower_id", "following_id"], name: "idx_follows_unique_pair", unique: true
    t.index ["follower_id", "following_id"], name: "index_follows_on_follower_id_and_following_id", unique: true
    t.index ["follower_id"], name: "index_follows_on_follower_id"
    t.index ["following_id"], name: "index_follows_on_following_id"
    t.check_constraint "follower_id <> following_id", name: "follows_no_self_follow"
  end

  create_table "ingredients", force: :cascade do |t|
    t.string "name", limit: 50, null: false
    t.string "amount", limit: 30, null: false
    t.bigint "recipe_id", null: false
    t.integer "order_number", default: 1
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["recipe_id", "order_number"], name: "index_ingredients_on_recipe_id_and_order_number"
    t.index ["recipe_id"], name: "index_ingredients_on_recipe_id"
  end

  create_table "ratings", force: :cascade do |t|
    t.integer "score"
    t.bigint "user_id", null: false
    t.bigint "recipe_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["recipe_id"], name: "index_ratings_on_recipe_id"
    t.index ["user_id", "recipe_id"], name: "idx_ratings_unique_user_recipe", unique: true
    t.index ["user_id", "recipe_id"], name: "index_ratings_on_user_id_and_recipe_id", unique: true
    t.index ["user_id"], name: "index_ratings_on_user_id"
    t.check_constraint "score >= 1 AND score <= 5", name: "ratings_score_range"
  end

  create_table "recipe_categories", force: :cascade do |t|
    t.bigint "recipe_id", null: false
    t.bigint "category_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category_id"], name: "index_recipe_categories_on_category_id"
    t.index ["recipe_id", "category_id"], name: "idx_recipe_categories_unique", unique: true
    t.index ["recipe_id", "category_id"], name: "index_recipe_categories_on_recipe_id_and_category_id", unique: true
    t.index ["recipe_id"], name: "index_recipe_categories_on_recipe_id"
  end

  create_table "recipes", force: :cascade do |t|
    t.string "title", limit: 30, null: false
    t.text "description", null: false
    t.integer "cooking_time", null: false
    t.integer "servings", null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "hidden", default: false, null: false
    t.integer "favorites_count", default: 0, null: false
    t.integer "comments_count", default: 0, null: false
    t.index ["comments_count"], name: "index_recipes_on_comments_count"
    t.index ["created_at"], name: "index_recipes_on_created_at"
    t.index ["favorites_count"], name: "index_recipes_on_favorites_count"
    t.index ["hidden"], name: "index_recipes_on_hidden"
    t.index ["title"], name: "index_recipes_on_title"
    t.index ["user_id"], name: "index_recipes_on_user_id"
  end

  create_table "reports", force: :cascade do |t|
    t.bigint "reporter_id", null: false, comment: "報告したユーザー"
    t.string "reportable_type", null: false
    t.bigint "reportable_id", null: false, comment: "報告対象"
    t.integer "reason", default: 3, null: false, comment: "報告理由"
    t.text "description", comment: "詳細説明"
    t.integer "status", default: 0, null: false, comment: "処理状況"
    t.bigint "admin_user_id", comment: "対応した管理者"
    t.text "admin_response", comment: "管理者からの回答"
    t.datetime "resolved_at", comment: "解決日時"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["admin_user_id"], name: "index_reports_on_admin_user_id"
    t.index ["created_at"], name: "index_reports_on_created_at"
    t.index ["reportable_type", "reportable_id"], name: "index_reports_on_reportable"
    t.index ["reporter_id", "reportable_type", "reportable_id"], name: "idx_reports_uniqueness_on_reporter_and_reportable", unique: true
    t.index ["reporter_id", "reportable_type", "reportable_id"], name: "index_reports_on_reporter_and_reportable", unique: true
    t.index ["reporter_id"], name: "index_reports_on_reporter_id"
    t.index ["status"], name: "index_reports_on_status"
    t.check_constraint "status = ANY (ARRAY[0, 1, 2, 3])", name: "reports_status_enum"
  end

  create_table "steps", force: :cascade do |t|
    t.text "instruction", null: false
    t.bigint "recipe_id", null: false
    t.integer "step_number", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["recipe_id", "step_number"], name: "index_steps_on_recipe_id_and_step_number", unique: true
    t.index ["recipe_id"], name: "index_steps_on_recipe_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "name", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "bio"
    t.boolean "admin", default: false, null: false
    t.boolean "suspended", default: false, null: false
    t.text "suspend_reason"
    t.datetime "suspend_until"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.inet "current_sign_in_ip"
    t.inet "last_sign_in_ip"
    t.datetime "suspended_until"
    t.index ["admin"], name: "index_users_on_admin"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["last_sign_in_at"], name: "index_users_on_last_sign_in_at"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["suspend_until"], name: "index_users_on_suspend_until"
    t.index ["suspended"], name: "index_users_on_suspended"
    t.index ["suspended_until"], name: "index_users_on_suspended_until"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "comments", "recipes", on_delete: :cascade
  add_foreign_key "comments", "users", on_delete: :cascade
  add_foreign_key "favorites", "recipes"
  add_foreign_key "favorites", "users"
  add_foreign_key "follows", "users", column: "follower_id"
  add_foreign_key "follows", "users", column: "following_id"
  add_foreign_key "ingredients", "recipes"
  add_foreign_key "ratings", "recipes"
  add_foreign_key "ratings", "users"
  add_foreign_key "recipe_categories", "categories"
  add_foreign_key "recipe_categories", "recipes"
  add_foreign_key "recipes", "users"
  add_foreign_key "reports", "users", column: "admin_user_id"
  add_foreign_key "reports", "users", column: "reporter_id"
  add_foreign_key "steps", "recipes"
end
