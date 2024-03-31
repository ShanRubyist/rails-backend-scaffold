# frozen_string_literal: true

class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :lockable, :timeoutable, :trackable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :confirmable

  # devise :omniauthable, omniauth_providers: [:google_oauth2]

  include DeviseTokenAuth::Concerns::User
end
