# == Schema Information
#
# Table name: tags
#
#  id         :bigint           not null, primary key
#  name       :string(256)      not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
RSpec.describe Tag, type: :model do
  describe "validations" do
    subject { build(:tag) }

    it { should validate_presence_of(:name) }
    it { should validate_length_of(:name).is_at_most(256) }
  end

  describe "assocations" do
    it { should have_many(:taggings) }
  end

  describe "scopes" do
    describe "alphabetized" do
      let!(:z_tag) { create(:tag, name: "Z") }
      let!(:a_tag) { create(:tag, name: "A") }

      it "retrieves tags in the correct order" do
        alphabetized_list = described_class.alphabetized

        expect(alphabetized_list.first).to eq(a_tag)
        expect(alphabetized_list.last).to eq(z_tag)
      end
    end

    describe "by_type" do
      let!(:tag) { create(:tag) }
      let!(:organization) { create(:organization) }
      let!(:product_drive) { create(:product_drive, organization:) }
      let!(:purchase) { create(:purchase, organization:) }
      let!(:product_drive_tagging) { create(:tagging, taggable: product_drive, organization:, tag:) }
      let!(:purchase_tagging) { create(:tagging, taggable: purchase, organization:, tag:) }

      it "only displays taggings of that type" do
        type = "ProductDrive"
        expect(described_class.by_type(type)).to eq([tag])
      end
    end
  end
end
