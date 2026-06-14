RSpec.describe "Admin::Comments 更新系", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:user)  { create(:user) }
  let(:recipe) { create(:recipe, user: user) }

  describe "PATCH /admin/comments/:id/hide" do
    let!(:comment) { create(:comment, recipe: recipe, user: user, hidden: false) }

      end
      context "未ログイン" do
        it "ログイン画面へリダイレクトされる" do
          patch hide_admin_comment_path(comment)
  
          expect(response).to have_http_status(:found)
          expect(response).to redirect_to(new_user_session_path)
        end
      end
      context "一般ユーザー" do
        before do
          sign_in user
        end
  
        it "rootへリダイレクトされ、コメントは非表示にならない" do
          patch hide_admin_comment_path(comment)
  
          expect(response).to have_http_status(:found)
          expect(response).to redirect_to(root_path)
          expect(comment.reload.hidden).to be false
        end
      end


    end