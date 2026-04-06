require "rails_helper"

RSpec.describe "Admin::Recipes 更新系", type: :request do
  let(:admin)  { create(:user, :admin) }
  let(:recipe) { create(:recipe) }

  let(:update_path)  { admin_recipe_path(recipe) }
  let(:destroy_path) { admin_recipe_path(recipe) }
  let(:hide_path)    { hide_admin_recipe_path(recipe) }
  let(:unhide_path)  { unhide_admin_recipe_path(recipe) }

  shared_examples "未ログインはログイン画面へ" do |verb, path_proc, params = nil|
    it "302でログイン画面へリダイレクトされ、DBは変更されない" do
      original_attrs = recipe.attributes.slice("title", "description", "cooking_time", "servings", "hidden")
      original_count = Recipe.count

      if params
        public_send(verb, instance_exec(&path_proc), params: params)
      else
        public_send(verb, instance_exec(&path_proc))
      end

      expect(response).to have_http_status(:found)
      expect(response).to redirect_to(new_user_session_path)

      if verb == :delete
        expect(Recipe.count).to eq(original_count)
      else
        recipe.reload
        expect(recipe.attributes.slice("title", "description", "cooking_time", "servings", "hidden"))
          .to eq(original_attrs)
      end
    end
  end

  shared_examples "一般ユーザーはrootへ" do |verb, path_proc, params = nil|
    it "302でrootへリダイレクトされ、DBは変更されない" do
      sign_in create(:user)

      original_attrs = recipe.attributes.slice("title", "description", "cooking_time", "servings", "hidden")
      original_count = Recipe.count

      if params
        public_send(verb, instance_exec(&path_proc), params: params)
      else
        public_send(verb, instance_exec(&path_proc))
      end

      expect(response).to have_http_status(:found)
      expect(response).to redirect_to(root_path)

      if verb == :delete
        expect(Recipe.count).to eq(original_count)
      else
        recipe.reload
        expect(recipe.attributes.slice("title", "description", "cooking_time", "servings", "hidden"))
          .to eq(original_attrs)
      end
    end
  end



  
end