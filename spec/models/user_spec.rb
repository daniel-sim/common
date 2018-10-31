require "rails_helper"

describe User do
  describe "#redact!" do
    let(:user) { create(:user) }

    it "redacts" do
      expect { user.redact! }.to change { user.email }
    end

    it "redacts username" do
      expect { user.redact! }.to change { user.username }
    end

    it "redacts website" do
      user.redact!

      expect(user.website).to start_with("https://pluginuseful.com/")
    end
  end
end
