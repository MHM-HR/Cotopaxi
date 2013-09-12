# Cotopaxi | Scrum Management Tool
# Copyright (C) 2012  MHM-Systemhaus GmbH
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
class Project < ActiveRecord::Base
  has_many :features, dependent: :destroy
  has_many :sprints, dependent: :destroy
  validates_presence_of :description, :name
  has_many :roles, dependent: :destroy
  has_many :users, through: :roles

  has_many :team_member_roles, -> { where role: 'team_member' }, class_name: Role.name
  has_many :team_members, through: :team_member_roles, source: :user

  has_many :stakeholder_roles, -> {where role: 'stakeholder' }, class_name: Role.name
  has_many :stakeholders, through: :stakeholder_roles, source: :user

  has_many :customer_roles, -> { where role: 'customer' }, class_name: Role.name
  has_many :customers, through: :customer_roles, source: :user

  has_one :scrum_master_role, -> {where role: 'scrum_master' }, class_name: Role.name
  has_one :scrum_master, through: :scrum_master_role, source: :user

  has_one :product_owner_role, -> { where role: 'product_owner' }, class_name: Role.name
  has_one :product_owner, through: :product_owner_role, source: :user


  SINGLE_ROLES = [:scrum_master, :product_owner]
  MANY_ROLES = [:customers, :stakeholders, :team_members]

  state_machine :state, initial: :created do
    #before_transition on:  :complete, do: :features_done?

    event :start do
      transition :created => :in_progress
    end

    event :complete do
      transition :in_progress => :done
    end
  end

  def project_ability(user)
    current_ability = Ability.new(user, self.id)
  end

  def features_done?
    counter = 0
    self.features.each do |feature|
      if feature.state == 'done'
          counter += 1
      end
    end
    if counter == features.length
      true
    else
      false
    end
  end

  def set_title_background
    status = {'created' => 'info', 'in_progress' => 'warning', 'done' => 'success'}
    status[self.state]
  end

  def set_state_change_button
    status = {'created' => 'Start!', 'in_progress' => 'Complete!', 'done' => 'Done!'}
    status[self.state]
  end

  def set_state_transition
    trans = {'created' => :start, 'in_progress' => :complete, 'done' => :done}
    trans[self.state]
  end

  def set_disabled_button
    status = {'created' => 'btn-success','in_progress' => self.complete_button, 'done' => 'disabled'}
    status[self.state]
  end

  def set_status_label
    status = {'created' => 'info', 'in_progress' => 'important', 'done' => 'success'}
    status[self.state]
  end

  def complete_button
    if self.features_done?
      'btn-success'
    else
      'btn-danger prevent'
    end
  end

  def drag_available
    if self.features_done?
      "no_drag"
    else
      "feature_table"
    end
  end

  def disable_new_feature
    if self.state == 'done'
      'disabled'
    else
      'btn-primary'
    end
  end

  def get_unassigned_features
    un_ass = []
    self.features.each do |feature|
      if feature.sprint.nil?
        un_ass << feature
      end
    end
    un_ass
  end

  def assign_roles(params)
    @role_to_be = Role.find(params[:id])
    @role_to_be.update_attributes(params)
  end

  def next_sprint_text
    if self.sprints.last
      case self.sprints.last.state
        when 'done'
          'Plan Next Sprint'
        when 'in_progress'
          'Review  Current Sprint'
        when 'created'
          'Review  Current Sprint'
        else
          'Plan Sprint'
      end
    else
      'Plan Sprint'
    end

  end
end
