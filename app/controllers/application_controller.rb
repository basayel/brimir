# Brimir is a helpdesk system to handle email support requests.
# Copyright (C) 2012-2015 Ivaldi http://ivaldi.nl
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

class ApplicationController < ActionController::Base
  rescue_from DeviseLdapAuthenticatable::LdapException do |exception|
    render text: exception, status: 500
  end
  protect_from_forgery

  #before_filter :authenticate_user!
  before_action :authenticate_user_from_token!, unless: :check_token_auth?
  before_filter :set_locale
  before_filter :load_labels, if: :user_signed_in?

  check_authorization unless: :devise_controller?

  def check_token_auth?
    devise_controller? or user_signed_in?
  end

  def authenticate_user_from_token!
    user_token = params[:auth_token].presence
    user = user_token && User.where(authentication_token: user_token.to_s).first

    if user && Devise.secure_compare(user.authentication_token, params[:auth_token])
      sign_in user, store: true
    else
      redirect_to new_user_session_url
    end
  end

  rescue_from CanCan::AccessDenied do |exception|
    if Rails.env == :production
      redirect_to root_url, alert: exception.message
    else
      # for tests and development, we want unauthorized status codes
      render text: exception, status: :unauthorized
    end
  end

  protected
    def load_labels
      @labels = Label.viewable_by(current_user).ordered
    end

    def set_locale
      if user_signed_in? && !current_user.locale.blank?
        I18n.locale = current_user.locale
      else
        locales = []

        Dir.open("#{Rails.root}/config/locales").each do |file|
          unless ['.', '..'].include?(file)
            # strip of .yml
            locales << file[0...-4]
          end
        end

        if AppSettings.ignore_user_agent_locale
          I18n.locale = I18n.default_locale
        else
          I18n.locale = http_accept_language.compatible_language_from(locales)
        end
        if user_signed_in?
          current_user.locale = I18n.locale
          current_user.save
        end
      end
    end

end
