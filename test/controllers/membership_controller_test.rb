require "test_helper"
require 'webmock/minitest'
require 'json'

class MembershipControllerTest < ActionDispatch::IntegrationTest
  soladi_mock_url = "https://my-soladi-url"
  soladi_token = "foobaa"

  setup do

    ENV['SOLADI_API_URL'] = soladi_mock_url
    ENV['SOLADI_API_SECRET_KEY'] = soladi_token
  end

  test "should show bidding form" do
    stub_request(:get, "#{soladi_mock_url}/api/magic_link/login?token=a-random-token").
      with(
        headers: {
          'Accept' => '*/*',
          'Authorization' => "Token token=#{soladi_token}",
          'Content-Type' => 'application/json',
        }).
      to_return(status: 200, body: file_fixture('soladi_response_with_old_bid.json').read, headers: {})

    get membership_url("a-random-token")

    assert_response :ok
    assert_select "div#new_bid_form"
    assert_select "form" do |element|
      assert_select "input#membership_shares"
    end
  end

  test "should show info for already placed bid" do
    stub_request(:get, "#{soladi_mock_url}/api/magic_link/login?token=a-random-token").
      with(
        headers: {
          'Accept' => '*/*',
          'Authorization' => "Token token=#{soladi_token}",
          'Content-Type' => 'application/json',
        }).
      to_return(status: 200, body: file_fixture('soladi_response_with_current_bid.json').read, headers: {})

    get membership_url("a-random-token")

    assert_response :ok
    assert_select "form", false, "This page must contain no forms"
    assert_select "div#current_bid"
  end

  test "should show not found for invalid token" do
    stub_request(:get, "#{soladi_mock_url}/api/magic_link/login?token=an-invalid-token").
      with(
        headers: {
          'Accept' => '*/*',
          'Authorization' => "Token token=#{soladi_token}",
          'Content-Type' => 'application/json',
        }).
      to_return(status: 404, body: "", headers: {})

    get membership_url("an-invalid-token")
    assert_redirected_to not_found_path
  end

  test "should deny if not logged in" do
    put membership_url("a-random-token"), params: { membership: { amount: 90.9, shares: 2, id: 1, name: "Max Mustermann" } }

    assert_redirected_to unauthorized_path
  end

  test "should create a new bid" do
    stub_request(:get, "#{soladi_mock_url}/api/magic_link/login?token=a-random-token").
      with(
        headers: {
          'Accept' => '*/*',
          'Authorization' => "Token token=#{soladi_token}",
          'Content-Type' => 'application/json',
        }).
      to_return(status: 200, body: file_fixture('soladi_response_with_old_bid.json').read, headers: {})

    stub_request(:post, "https://my-soladi-url/api/bids").
      with(
        body: "{\"bid\":{\"start_date\":\"2022-04-01\",\"end_date\":\"2023-03-31\",\"person_id\":1,\"membership_id\":1,\"amount\":90.9,\"shares\":2}}",
        headers: {
          'Accept' => '*/*',
          'Authorization' => 'Token token=foobaa',
          'Content-Type' => 'application/json',
        }).
      to_return(status: 202, body: file_fixture("soladi_bid_created_response.json"), headers: {})

    get membership_url("a-random-token")
    put membership_url("a-random-token"), params: { membership: { amount: 90.9, shares: 2, id: 1, name: "Max Mustermann" } }

    assert_response :ok
  end
end
