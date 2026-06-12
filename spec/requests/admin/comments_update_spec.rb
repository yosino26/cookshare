RSpec.describe "Admin::Comments 更新系", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:user)  { create(:user) }
  let(:recipe) { create(:recipe, user: user) }

  describe "PATCH /admin/comments/:id/hide" do
    let!(:comment) { create(:comment, recipe: recipe, user: user, hidden: false) }

      end
    end