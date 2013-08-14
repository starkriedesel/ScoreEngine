require 'spec_helper'

feature 'the sign in process' do
  background do
    @user = create(:user) # use to test sign in
    @new_user = build(:user1) # use to test sign up (gets added to DB)
  end

  scenario 'sign up button goes to registration page'  do
    # Click Sign Up button
    visit '/users/sign_in'
    click_on 'Sign Up'
    current_path.should == new_user_registration_path
    @user.username.should_not == @new_user.username
  end

  scenario 'it signs me up' do
    visit '/users/sign_up'
    sign_up_form @new_user.username, @new_user.password
    current_path.should == services_path
    page.should have_content 'You have signed up successfully'
    # TODO: check for use in DB
  end

  scenario 'it signs me in' do
    visit '/users/sign_in'
    sign_in_form @user.username, @user.password
    page.should have_content 'Signed in successfully'
    current_path.should == services_path
  end

  scenario 'it rejects sign in with wrong password' do
    visit '/users/sign_in'
    sign_in_form @user.username, @user.password+'x'
    page.should have_content 'Invalid email or password'
    current_path.should == new_user_session_path
  end

  scenario 'it alerts when signing up with a short password' do
    visit '/users/sign_up'
    # Password of growing size
    #  includes password of zero size and large enough
    (User::PASS_MIN_LENGTH + 1).times do |n|
      sign_up_form @new_user.username, 'z'*n
      if n < User::PASS_MIN_LENGTH
        current_path.should == '/users'
        page.should have_content (n == 0 ? 'Password can\'t be blank' : 'Password is too short')
      else
        current_path.should == services_path
        page.should have_content 'You have signed up successfully'
      end
    end
  end

  scenario 'it alerts when signing up with no username' do
    visit '/users/sign_up'
    sign_up_form '', @user.password
    current_path.should == '/users'
    page.should have_content 'Username can\'t be blank'
  end

  scenario 'it alerts when signing up with username already taken' do
    visit '/users/sign_up'
    sign_up_form @user.username, @user.password
    current_path.should == '/users'
    page.should have_content 'Username has already been taken'
  end

  def sign_up_form(username, password, is_sign_up=true)
    within '#new_user' do
      fill_in 'Username', with: username
      fill_in 'Password', with: password
      if is_sign_up # confirm only on sign up page
        fill_in 'Password confirmation', with: password
      end
    end
    #save_and_open_page
    click_on is_sign_up ? 'Sign Up' : 'Sign In'
  end
  
  def sign_in_form(username, password, is_sign_in=true)
    sign_up_form username, password, !is_sign_in
  end
end
