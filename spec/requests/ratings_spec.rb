require 'rails_helper'

RSpec.describe "Ratings", type: :request do
  let(:user)   { create(:user) }
  let(:recipe) { create(:recipe) }

  describe "POST /recipes/:recipe_id/ratings" do
    context "ログイン済みのとき" do
      before do
        sign_in user
      end

      it "レシピに評価を1件登録できること" do
        expect {
          post recipe_ratings_path(recipe), params: { score: 4 }
        }.to change { recipe.ratings.count }.by(1)

        rating = recipe.ratings.last
        expect(rating.user).to  eq user
        expect(rating.score).to eq 4

        expect(response).to have_http_status(:found) # 302
        expect(response).to redirect_to(recipe_path(recipe))
        expect(flash[:notice]).to eq '評価を投稿しました'
      end

      it "同じユーザーが再度評価するとスコアが上書きされること" do
        create(:rating, recipe: recipe, user: user, score: 2)

        expect {
          post recipe_ratings_path(recipe), params: { score: 5 }
        }.not_to change { recipe.ratings.count }

        expect(recipe.ratings.find_by(user: user).score).to eq 5
        expect(response).to redirect_to(recipe_path(recipe))
      end

      it "スコアは1〜5の範囲に丸められること" do
        post recipe_ratings_path(recipe), params: { score: 100 }
        expect(recipe.ratings.find_by(user: user).score).to eq 5

        post recipe_ratings_path(recipe), params: { score: 0 }
        expect(recipe.ratings.find_by(user: user).score).to eq 1
      end
    end

    context "未ログインのとき" do
      it "評価は作成されずログイン画面へリダイレクトされること" do
        expect {
          post recipe_ratings_path(recipe), params: { score: 4 }
        }.not_to change { Rating.count }

        expect(response).to have_http_status(:found)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end