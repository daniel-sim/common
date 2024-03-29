# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2019_05_20_170125) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "admins", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_admins_on_email", unique: true
    t.index ["reset_password_token"], name: "index_admins_on_reset_password_token", unique: true
  end

  create_table "promo_codes", id: :serial, force: :cascade do |t|
    t.string "code", null: false
    t.string "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "expires_at"
    t.decimal "value", precision: 5, scale: 2, default: "100.0", null: false
    t.integer "created_by_id"
    t.index ["code"], name: "index_promo_codes_on_code"
    t.index ["created_by_id"], name: "index_promo_codes_on_created_by_id"
  end

  create_table "shops", force: :cascade do |t|
    t.string "shopify_plan"
    t.string "shopify_domain"
    t.string "shopify_token", null: false
    t.boolean "uninstalled", default: false, null: false
    t.string "app_plan"
    t.integer "promo_code_id"
    t.index ["app_plan"], name: "index_shops_on_app_plan"
    t.index ["promo_code_id"], name: "index_shops_on_promo_code_id"
    t.index ["shopify_domain"], name: "index_shops_on_shopify_domain"
  end

  create_table "time_periods", force: :cascade do |t|
    t.datetime "start_time", default: -> { "now()" }, null: false
    t.datetime "end_time"
    t.integer "kind", default: 0, null: false
    t.datetime "shop_retained_analytic_sent_at"
    t.bigint "shop_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "converted_to_paid_at"
    t.decimal "monthly_usd", default: "0.0", null: false
    t.datetime "period_last_paid_at"
    t.integer "periods_paid", default: 0, null: false
    t.index ["converted_to_paid_at"], name: "index_time_periods_on_converted_to_paid_at"
    t.index ["end_time"], name: "index_time_periods_on_end_time"
    t.index ["kind"], name: "index_time_periods_on_kind"
    t.index ["period_last_paid_at"], name: "index_time_periods_on_period_last_paid_at"
    t.index ["shop_id"], name: "index_time_periods_on_shop_id"
    t.index ["shop_retained_analytic_sent_at"], name: "index_time_periods_on_shop_retained_analytic_sent_at"
    t.index ["start_time"], name: "index_time_periods_on_start_time"
  end

  create_table "users", id: :serial, force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.string "name"
    t.boolean "confirmed"
    t.string "access_token"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "active_charge", default: false
    t.integer "shop_id"
    t.string "referrer"
    t.integer "provider"
    t.datetime "charged_at"
    t.string "username", null: false
    t.string "website", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["provider"], name: "index_users_on_provider"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["username"], name: "index_users_on_username"
  end

end
