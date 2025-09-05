class CommentsController < ApplicationController
  before_action :set_recipe
  before_action :set_comment, only: [:destroy]

  def create
    @comment = @recipe.comments.build(comment_params)
    @comment.user = current_user
    
    if @comment.save
      redirect_to @recipe, notice: 'コメントを投稿しました'
    else
      redirect_to @recipe, alert: 'コメントの投稿に失敗しました'
    end
  end

  def destroy
    if @comment.user == current_user
      @comment.destroy
      redirect_to @recipe, notice: 'コメントを削除しました'
    else
      redirect_to @recipe, alert: '削除できません'
    end
  end

  
  private
  def set_recipe
    @recipe = Recipe.find(params[:recipe_id])
  end

  def set_comment
    @comment = @recipe.comments.find(params[:id])
  end

  def comment_params
    params.require(:comment).permit(:content)
  end
end
