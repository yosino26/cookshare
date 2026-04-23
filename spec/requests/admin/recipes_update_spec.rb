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

  describe "PATCH /admin/recipes/:id" do
    let(:valid_params) do
      {
        recipe: {
          title: "更新後タイトル",
          description: "更新後の説明文です",
          cooking_time: 25,
          servings: 4
        }
      }
    end

    let(:invalid_params) do
      {
        recipe: {
          title: "",
          description: "更新後の説明文です",
          cooking_time: 25,
          servings: 4
        }
      }
    end

    include_examples "未ログインはログイン画面へ", :patch, -> { update_path }, {
      recipe: { title: "変更タイトル" }
    }
    include_examples "一般ユーザーはrootへ", :patch, -> { update_path }, {
      recipe: { title: "変更タイトル" }
    }

    context "管理者" do
      before { sign_in admin }

      it "有効なパラメータで更新できる" do
        patch update_path, params: valid_params

        expect(response).to have_http_status(:found)
        expect(response).to redirect_to(admin_recipe_path(recipe))

        recipe.reload
        expect(recipe.title).to eq("更新後タイトル")
        expect(recipe.description).to eq("更新後の説明文です")
        expect(recipe.cooking_time).to eq(25)
        expect(recipe.servings).to eq(4)
      end

      it "無効なパラメータでは更新されず422を返す" do
        original_attrs = recipe.attributes.slice("title", "description", "cooking_time", "servings")

        patch update_path, params: invalid_params

        expect(response).to have_http_status(:unprocessable_content)

        recipe.reload
        expect(recipe.attributes.slice("title", "description", "cooking_time", "servings"))
          .to eq(original_attrs)
      end
      
      it "hidden属性も更新できる" do
        expect(recipe.hidden).to eq(false)

        patch update_path, params: { recipe: { hidden: true } }

        expect(response).to have_http_status(:found)
        expect(response).to redirect_to(admin_recipe_path(recipe))

        recipe.reload
        expect(recipe.hidden).to eq(true)
      end
    end
  end

  describe "DELETE /admin/recipes/:id" do
    include_examples "未ログインはログイン画面へ", :delete, -> { destroy_path }
    include_examples "一般ユーザーはrootへ", :delete, -> { destroy_path }

    context "管理者" do
      before { sign_in admin }

      it "レシピを削除できる" do
        recipe

        expect do
          delete destroy_path
        end.to change(Recipe, :count).by(-1)

        expect(response).to have_http_status(:found)
        expect(response).to redirect_to(admin_recipes_path)
      end
    end
  end

  describe "PATCH /admin/recipes/:id/hide" do
    include_examples "未ログインはログイン画面へ", :patch, -> { hide_path }
    include_examples "一般ユーザーはrootへ", :patch, -> { hide_path }

    context "管理者" do
      before { sign_in admin }

      it "レシピを非公開にできる" do
        expect(recipe.hidden).to eq(false)

        patch hide_path

        expect(response).to have_http_status(:found)
        expect(response).to redirect_to(admin_recipes_path)

        recipe.reload
        expect(recipe.hidden).to eq(true)
      end
    end
  end

  describe "PATCH /admin/recipes/:id/unhide" do
    before do
      recipe.update!(hidden: true)
    end

    include_examples "未ログインはログイン画面へ", :patch, -> { unhide_path }
    include_examples "一般ユーザーはrootへ", :patch, -> { unhide_path }
    context "管理者" do
      before { sign_in admin }

      it "レシピを公開に戻せる" do
        patch unhide_path

        expect(response).to have_http_status(:found)
        expect(response).to redirect_to(admin_recipes_path)

        recipe.reload
        expect(recipe.hidden).to eq(false)
      end
    end
  end
  
end