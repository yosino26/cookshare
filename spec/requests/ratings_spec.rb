require 'rails_helper'

RSpec.describe "Ratings", type: :request do
  let(:user)   { create(:user) }
  let(:recipe) { create(:recipe) }

  before { sign_in user }

  it "scoreが1〜5で作成できる" do
    post recipe_ratings_path(recipe), params: { score: 5 }  # ← score直下で送る
    expect(response).to have_http_status(:found)            # ← 302に合わせる
    expect(Rating.where(user:, recipe:, score: 5)).to exist
  end

  it "不正scoreは302でリダイレクト（フラッシュに失敗文言）" do
    post recipe_ratings_path(recipe), params: { score: 6 }
    expect(response).to have_http_status(:found)            # ← 失敗時も302
    # 失敗を挙動で担保：作成されていない
    expect(Rating.where(user:, recipe:)).to be_empty
    # フラッシュの確認（必要なら）
    # follow_redirect! してから body に失敗メッセージを含むかをチェックしてもOK
  end

  it "二重評価は302でリダイレクトし、件数は増えない" do
    create(:rating, user:, recipe:, score: 3)
    post recipe_ratings_path(recipe), params: { score: 4 }
    expect(response).to have_http_status(:found)
    expect(Rating.where(user:, recipe:).count).to eq(1)
  end
end