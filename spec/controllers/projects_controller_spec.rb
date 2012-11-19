require 'spec_helper'
require "factory_girl"

describe ProjectsController do
  context "create & show fictional project" do
    before do
      @user = FactoryGirl.create(:admin)
      sign_in @user
      project = FactoryGirl.build(:project)
      project.roles << Role.new(role: :product_owner, project_id: project.id, user_id: @user.id)
      project.roles << Role.new(role: :scrum_master, project_id: project.id)
      project.save!
      get :show, id: 1
    end

    it { should respond_with :success }
    it { should render_template :show }
    it { should_not set_the_flash }

    context "show edit projects form" do
      before do
        sign_in @user
        get :edit, id: 1
      end
      it {should }
      it { should respond_with :success }
      it {should render_template :edit}
      it { should_not set_the_flash }
    end

    context "show projects' index" do
      before do
        sign_in @user
        get :index
      end

      it { should respond_with :success }
      it { should render_template :index }
      it { should_not set_the_flash }
    end
  end

  context 'test for CanCan exception' do
    before do
      @user = FactoryGirl.create(:user)
      sign_in @user
      get :new
    end
    it { should set_the_flash }
    it { should redirect_to projects_url}
  end

  context "POST" do
    before do
      @user = FactoryGirl.create(:admin)
      sign_in @user
    end
    def do_request
      post :create, {"project"=>{"name"=>"Test 1", "description"=>"Test1", "sprint_duration"=>"604800"}}
    end
    context "create" do
      context "success" do
        before {do_request}
        it {should assign_to :project}
        it { should respond_with :redirect }
      end

      context 'failure' do
        before do
          Project.any_instance.stub(:save).and_return false
          do_request
        end
        it {should render_template :new}
      end
    end

    context "update" do
      def update_request
        project = FactoryGirl.create(:project)
        post :update, {"project"=>{"name"=>"Test 1", "description"=>"Test3", "sprint_duration"=>"604800"}, "id"=>project.id}
      end
      context "success" do
        before {update_request}
        it {should assign_to :project}
        it { should respond_with :redirect }
      end

      context 'failure' do
        before do
          Project.any_instance.stub(:save).and_return false
          update_request
        end
        it {should render_template :edit}
      end
    end

    context "sort_features" do
      before do
        project = FactoryGirl.create(:project)
        @features = []
        (0..4).each do
          feature = FactoryGirl.build(:feature)
          feature.difficulty = 3
          feature.project = project
          feature.save!
          @features << feature.id
        end
        post :sort_features, {"order"=>@features, "id"=>project.id}
      end
      it {should respond_with 406}
    end

    context "assign_roles" do
      before do
        project = FactoryGirl.build(:project)
        project.roles << Role.new(role: :product_owner, project_id: project.id, user_id: @user.id)
        project.save!
        post :assign_roles, {"role"=>{"project_id"=>project.id, "role"=>"scrum_master", "id"=>project.roles[0].id, "user_id"=>@user.id}, "id"=>project.id}
      end
      it {should respond_with 302}
    end

    context "confirm_sprint" do
      def generate_data
        project = FactoryGirl.create(:project)
        feature = FactoryGirl.build(:feature)
        feature.difficulty = 3
        feature.project = project
        feature.save!
        sprint = Sprint.new
        sprint.project = project
        sprint.save!
      end
      context "put feature in sprint" do
        before do
          generate_data
          post :confirm_sprint, {"feature_id"=>feature.id, "sprint_id"=>sprint.id, "id"=>project.id}
        end
        it {should respond_with 406}
      end

      context "remove feature form sprint" do
        before do
          generate_data
          post :confirm_sprint, {"feature_id"=>feature.id, "sprint_id"=>"0", "id"=>project.id}
        end
        it {should respond_with 406}
      end
    end
  end
end