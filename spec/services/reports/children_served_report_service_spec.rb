RSpec.describe Reports::ChildrenServedReportService, type: :service do
  let(:year) { 2020 }
  let(:within_time) { Time.zone.parse("2020-05-31 14:00:00") }
  let(:outside_time) { Time.zone.parse("2019-05-31 14:00:00") }

  describe '#report' do
    it 'should report zero values' do
      organization = create(:organization)
      report = described_class.new(organization: organization, year: year).report
      expect(report).to eq({
        name: 'Children Served',
        entries: {
          'Average children served monthly' => "0.0",
          'Total children served' => "0",
          'Repackages diapers?' => 'N',
          'Monthly diaper distributions?' => 'N'
        }
      })
    end

    it 'should report normal values' do
      organization = create(:organization, :with_items, distribute_monthly: true, repackage_essentials: true)

      disposable_item = organization.items.disposable.first
      disposable_item.update!(distribution_quantity: 20)
      non_disposable_item = organization.items.where.not(id: organization.items.disposable).first

      # Kits
      kit = create(:kit, organization: organization)

      create(:base_item, name: "Toddler Disposable Diaper", partner_key: "toddler diapers", category: "disposable diaper")
      create(:base_item, name: "Infant Disposable Diaper", partner_key: "infant diapers", category: "infant disposable diaper")

      toddler_disposable_kit_item = create(:item, name: "Toddler Disposable Diapers", partner_key: "toddler diapers", kit:, distribution_quantity: 2, organization:)
      infant_disposable_kit_item = create(:item, name: "Infant Disposable Diapers", partner_key: "infant diapers", kit:, organization:)

      # Distributions
      distributions = create_list(:distribution, 2, issued_at: within_time, organization: organization)
      outside_distributions = create_list(:distribution, 2, issued_at: outside_time, organization: organization)
      (distributions + outside_distributions).each do |dist|
        create_list(:line_item, 5, :distribution, quantity: 200, item: disposable_item, itemizable: dist)
        create_list(:line_item, 5, :distribution, quantity: 300, item: non_disposable_item, itemizable: dist)
      end

      infant_distribution = create(:distribution, organization: organization, issued_at: within_time)
      toddler_distribution = create(:distribution, organization: organization, issued_at: within_time)

      create(:line_item, quantity: 10, item: toddler_disposable_kit_item, itemizable: infant_distribution)
      create(:line_item, quantity: 10, item: infant_disposable_kit_item, itemizable: toddler_distribution)
      create(:line_item, quantity: 10, item: toddler_disposable_kit_item, itemizable: toddler_distribution)

      report = described_class.new(organization: organization, year: within_time.year).report
      expect(report).to eq({
        name: 'Children Served',
        entries: {
          'Average children served monthly' => "10.0",
          'Total children served' => "120", # 100 normal and 20 from kits (10 infant, 10 toddler)
          'Repackages diapers?' => 'Y',
          'Monthly diaper distributions?' => 'Y'
        }
      })
    end

    it 'should work with no distribution_quantity' do
      organization = create(:organization, :with_items, distribute_monthly: true, repackage_essentials: true)

      within_time = Time.zone.parse("2020-05-31 14:00:00")
      outside_time = Time.zone.parse("2019-05-31 14:00:00")

      disposable_item = organization.items.disposable.first
      non_disposable_item = organization.items.where.not(id: organization.items.disposable).first

      # Kits
      kit = create(:kit, organization: organization)

      create(:base_item, name: "Toddler Disposable Diaper", partner_key: "toddler diapers", category: "disposable diaper")
      create(:base_item, name: "Infant Disposable Diaper", partner_key: "infant diapers", category: "infant disposable diaper")

      toddler_disposable_kit_item = create(:item, name: "Toddler Disposable Diapers", partner_key: "toddler diapers", kit: kit)
      infant_disposable_kit_item = create(:item, name: "Infant Disposable Diapers", partner_key: "infant diapers", kit: kit)

      # Distributions
      distributions = create_list(:distribution, 2, issued_at: within_time, organization: organization)
      outside_distributions = create_list(:distribution, 2, issued_at: outside_time, organization: organization)
      (distributions + outside_distributions).each do |dist|
        create_list(:line_item, 5, :distribution, quantity: 200, item: disposable_item, itemizable: dist)
        create_list(:line_item, 5, :distribution, quantity: 300, item: non_disposable_item, itemizable: dist)
      end

      infant_distribution = create(:distribution, organization: organization, issued_at: within_time)
      toddler_distribution = create(:distribution, organization: organization, issued_at: within_time)

      create(:line_item, :distribution, quantity: 10, item: toddler_disposable_kit_item, itemizable: infant_distribution)
      create(:line_item, :distribution, quantity: 20, item: toddler_disposable_kit_item, itemizable: toddler_distribution)
      create(:line_item, :distribution, quantity: 30, item: infant_disposable_kit_item, itemizable: toddler_distribution)

      report = described_class.new(organization: organization, year: within_time.year).report
      expect(report).to eq({
        name: 'Children Served',
        entries: {
          'Average children served monthly' => "8.33",
          'Total children served' => "100", # 40 normal and 60 from kits
          'Repackages diapers?' => 'Y',
          'Monthly diaper distributions?' => 'Y'
        }
      })
    end

    it "rounds children served to integer ceiling" do
      organization = create(:organization, :with_items)

      disposable_item = organization.items.disposable.first
      disposable_item.update!(distribution_quantity: 20)

      # Kits
      kit = create(:kit, organization: organization)
      create(:base_item, name: "Toddler Disposable Diaper", partner_key: "toddler diapers", category: "disposable diaper")
      toddler_disposable_kit_item = create(:item, name: "Toddler Disposable Diapers", partner_key: "toddler diapers", kit:, organization:, distribution_quantity: 10)

      # Distributions
      distributions = create_list(:distribution, 2, issued_at: within_time, organization: organization)
      distributions.each do |dist|
        create_list(:line_item, 2, :distribution, quantity: 6, item: disposable_item, itemizable: dist)
      end

      toddler_distribution = create(:distribution, organization: organization, issued_at: within_time)
      create(:line_item, quantity: 1, item: toddler_disposable_kit_item, itemizable: toddler_distribution)

      report = described_class.new(organization: organization, year: within_time.year).report
      expect(report).to eq({
        name: "Children Served",
        entries: {
          "Average children served monthly" => "0.25",
          "Total children served" => "3", # 1 / 10 = 0.1 rounds to 1 child from kits + 6 / 20 * 4 = 1.25 rounds to 2 children from nonkits
          "Repackages diapers?" => "N",
          "Monthly diaper distributions?" => "N"
        }
      })
    end
  end
end
