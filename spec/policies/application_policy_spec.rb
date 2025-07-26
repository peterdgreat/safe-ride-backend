# spec/policies/application_policy_spec.rb
require 'rails_helper'

RSpec.describe ApplicationPolicy, type: :policy do
  let(:user) { User.new } # A generic user for testing

  subject { described_class.new(user, nil) } # Initialize policy with user and nil record

  it 'denies access for index? by default' do
    expect(subject.index?).to be_falsey
  end

  it 'denies access for show? by default' do
    expect(subject.show?).to be_falsey
  end

  it 'denies access for create? by default' do
    expect(subject.create?).to be_falsey
  end

  it 'denies access for new? by default' do
    expect(subject.new?).to be_falsey
  end

  it 'denies access for update? by default' do
    expect(subject.update?).to be_falsey
  end

  it 'denies access for edit? by default' do
    expect(subject.edit?).to be_falsey
  end

  it 'denies access for destroy? by default' do
    expect(subject.destroy?).to be_falsey
  end

  describe 'Scope' do
    let(:scope) { double('scope') }
    subject { described_class::Scope.new(user, scope) }

    it 'raises NoMethodError for resolve by default' do
      expect { subject.resolve }.to raise_error(NoMethodError, /You must define #resolve in/)
    end
  end
end
