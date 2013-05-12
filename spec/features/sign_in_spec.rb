require 'spec_helper'

feature 'the signin process' do
  background do
    @user = create(:user)
  end

  scenario 'it signs me in' do
    sign_in @user.username, @user.password
    page.should have_content 'Signed in successfully'
    current_path.should == services_path
  end

  scenario 'rejects wrong password' do
    sign_in @user.username, @user.password+'x'
    page.should have_content 'Invalid email or password'
    current_path.should == new_user_session_path
  end

  def sign_in username, password
    visit '/users/sign_in'
    within '#new_user' do
      fill_in 'Username', with: username
      fill_in 'Password', with: password
    end
    click_on 'Sign in'
  end
end