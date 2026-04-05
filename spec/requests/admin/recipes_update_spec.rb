require "rails_helper"

RSpec.describe "Admin::Recipes 更新系", type: :request do
  let(:admin)  { create(:user, :admin) }
  let(:recipe) { create(:recipe) }

  let(:update_path)  { admin_recipe_path(recipe) }
  let(:destroy_path) { admin_recipe_path(recipe) }
  let(:hide_path)    { hide_admin_recipe_path(recipe) }
  let(:unhide_path)  { unhide_admin_recipe_path(recipe) }

  shared_examples "未ログインはログイン画面へ" do |verb, path_proc, params = nil|



  end