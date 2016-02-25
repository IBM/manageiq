describe Tag do
  context ".filter_ns" do
    it "normal case" do
      tag1 = double
      allow(tag1).to receive(:name).and_return("/managed/abc")
      expect(described_class.filter_ns([tag1], "/managed")).to eq(["abc"])
    end

    it "tag == namespace" do
      tag1 = double
      allow(tag1).to receive(:name).and_return("/managed")
      expect(described_class.filter_ns([tag1], "/managed")).to eq([])
    end

    it "tag == namespace and a second tag" do
      tag1 = double
      allow(tag1).to receive(:name).and_return("/managed")

      tag2 = double
      allow(tag2).to receive(:name).and_return("/managed/abc")
      expect(described_class.filter_ns([tag1, tag2], "/managed")).to eq(["abc"])
    end

    it "empty tag" do
      tag1 = double
      allow(tag1).to receive(:name).and_return("/managed/")

      expect(described_class.filter_ns([tag1], "/managed")).to eq([])
    end

    it "nil namespace" do
      expect(described_class.filter_ns(["/managed/abc"], nil)).to eq(["/managed/abc"])
    end

    it "nil namespace with nil tag" do
      expect(described_class.filter_ns([nil, "/managed/abc"], nil)).to eq(["/managed/abc"])
    end
  end

  context "categorization" do
    before(:each) do
      FactoryGirl.create(:classification_department_with_tags)

      @tag            = Tag.find_by_name("/managed/department/finance")
      @category       = Classification.find_by_name("department")
      @classification = @tag.classification
    end

    it "tag category should match category" do
      expect(@tag.category).to eq(@category)
    end

    it "tag show should reflect category show" do
      expect(@tag.show).to eq(@category.show)
    end

    it "tag categorization" do
      categorization = @tag.categorization
      expected_categorization = {"name"         => @classification.name,
                                 "description"  => @classification.description,
                                 "category"     => {"name" => @category.name, "description" => @category.description},
                                 "display_name" => "#{@category.description}: #{@classification.description}"}

      expect(categorization).to eq(expected_categorization)
    end
  end

  describe ".find_by_classification_name" do
    let(:root_ns)   { "/managed" }
    let(:parent_ns) { "/managed/test_category" }
    let(:entry_ns)  { "/managed/test_category/test_entry" }
    let(:my_region_number) { Tag.my_region_number }
    let(:parent) { FactoryGirl.create(:classification, :name => "test_category") }

    before do
      FactoryGirl.create(:classification_tag,      :name => "test_entry",         :parent => parent)
      FactoryGirl.create(:classification_tag,      :name => "another_test_entry", :parent => parent)
    end

    it "finds tag by name" do
      expect(Tag.find_by_classification_name("test_category")).not_to be_nil
      expect(Tag.find_by_classification_name("test_category").name).to eq(parent_ns)
    end

    it "doesn't find non tag" do
      expect(Tag.find_by_classification_name("test_entry")).to be_nil
    end

    it "finds tag by name and ns" do
      expect(Tag.find_by_classification_name("test_entry", nil, parent_ns)).not_to be_nil
      expect(Tag.find_by_classification_name("test_entry", nil, parent_ns).name).to eq(entry_ns)
    end

    it "finds tag by name, ns, and parent_id" do
      expect(Tag.find_by_classification_name("test_entry", nil, root_ns, parent.id)).not_to be_nil
      expect(Tag.find_by_classification_name("test_entry", nil, root_ns, parent.id).name).to eq(entry_ns)
    end

    it "finds tag by name, ns and parent" do
      expect(Tag.find_by_classification_name("test_entry", nil, root_ns, parent)).not_to be_nil
      expect(Tag.find_by_classification_name("test_entry", nil, root_ns, parent).name).to eq(entry_ns)
    end

    it "finds tag in region" do
      expect(Tag.find_by_classification_name("test_category", my_region_number)).not_to be_nil
    end

    it "filters tag in wrong region" do
      expect(Tag.find_by_classification_name("test_category", my_region_number + 1)).to be_nil
    end

    it "find tag in any region" do
      expect(Tag.find_by_classification_name("test_category", nil)).not_to be_nil
    end
  end

  describe "#destroy" do
    let(:miq_group)       { FactoryGirl.create(:miq_group) }
    let(:other_miq_group) { FactoryGirl.create(:miq_group) }
    let(:filters)         { [["/managed/prov_max_memory/test"], ["/managed/my_name/test"]] }
    let(:tag)             { FactoryGirl.create(:tag, :name => "/managed/my_name/test") }

    before :each do
      miq_group.set_managed_filters(filters)
      other_miq_group.set_managed_filters(filters)
      [miq_group, other_miq_group].each(&:save)
    end

    it "destroys tag and remove it from all groups's managed filters" do
      tag.destroy

      expected_filters = [["/managed/prov_max_memory/test"]]
      MiqGroup.all.each { |group| expect(group.get_managed_filters).to match_array(expected_filters) }
      expect(Tag.all).to be_empty
    end
  end
end
