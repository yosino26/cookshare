class Admin::CommentsController < ApplicationController
  def index
    @comments = Comment.includes(:user, :recipe)
                       .order(created_at: :desc)
                       .page(params[:page]).per(12)
  end

  def destroy
    comment = Comment.find(params[:id])
    comment.destroy
    redirect_back fallback_location: admin_comments_path, notice: 'コメントを削除しました'
  end
end
