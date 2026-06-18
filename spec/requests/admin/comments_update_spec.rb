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
      context "管理者" do
        before do
          sign_in admin
        end
  
        it "コメントを非表示にできる" do
          patch hide_admin_comment_path(comment)
  
          expect(response).to have_http_status(:found)
          expect(response).to redirect_to(admin_comments_path)
          expect(comment.reload.hidden).to be true
        end
      end
    end
    describe "PATCH /admin/comments/:id/unhide" do
      let!(:comment) { create(:comment, recipe: recipe, user: user, hidden: true) }
  
      context "管理者" do
        before do
          sign_in admin
        end
  
        it "コメントを再表示できる" do
          patch unhide_admin_comment_path(comment)
  
          expect(response).to have_http_status(:found)
          expect(response).to redirect_to(admin_comments_path)
          expect(comment.reload.hidden).to be false
        end
      end
    end
    describe "DELETE /admin/comments/:id" do
      let!(:comment) { create(:comment, recipe: recipe, user: user) }
  
      context "管理者" do
        before do
          sign_in admin
        end
  
        it "コメントを削除できる" do
          expect {
            delete admin_comment_path(comment)
          }.to change(Comment, :count).by(-1)
  
          expect(response).to have_http_status(:found)
          expect(response).to redirect_to(admin_comments_path)
        end
      end
    end
    describe "PATCH /admin/comments/bulk" do
      let!(:comment1) { create(:comment, recipe: recipe, user: user, hidden: false) }
      let!(:comment2) { create(:comment, recipe: recipe, user: user, hidden: false) }
  
      context "管理者" do
        before do
          sign_in admin
        end
  
        it "複数コメントをまとめて非表示にできる" do
          patch bulk_admin_comments_path, params: {
            comment_ids: [comment1.id, comment2.id],
            bulk_action: "hide"
          }
  
          expect(response).to have_http_status(:found)
          expect(response).to redirect_to(admin_comments_path)
          expect(comment1.reload.hidden).to be true
          expect(comment2.reload.hidden).to be true
        end


    end