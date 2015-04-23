class Api::V1::RegistrationsController < ActionController::Base

  def create
    if user_params.present?
      user = User.new(user_params)
      puts user.valid?
      puts user.errors.full_messages
      puts user_params
      return render json: { saved: user.save }.to_json
    end
    return render json: { error: 'Wrong credentials' }.to_json, status: :unauthorized
  end

  def user_params
    attributes = params.require(:user).permit(
      :username,
      :email,
      :password,
      :password_confirmation,
      :remember_me,
      :signature,
      :agent,
      :notify,
      :time_zone,
      :locale,
      :per_page,
      label_ids: []
    )

    # prevent normal user from changing email and role
    #unless current_user.agent?
    #  attributes.delete(:email)
    #  attributes.delete(:agent)
    #  attributes.delete(:label_ids)
    #end

    return attributes
  end

end
