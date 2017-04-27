RSpec.describe Discard::Model do
  context "with simple Post model" do
    with_model :Post, scope: :all do
      table do |t|
        t.string :title
        t.datetime :discarded_at
        t.timestamps null: false
      end

      model do
        include Discard::Model
      end
    end

    context "an undiscarded Post" do
      let!(:post) { Post.create!(title: "My very first post") }

      it "is included in the default scope" do
        expect(Post.all).to eq([post])
      end

      it "is included in kept scope" do
        expect(Post.kept).to eq([post])
      end

      it "is included in undiscarded scope" do
        expect(Post.undiscarded).to eq([post])
      end

      it "is not included in discarded scope" do
        expect(Post.discarded).to eq([])
      end

      it "should not be discarded?" do
        expect(post).not_to be_discarded
      end

      describe '#discard' do
        it "sets discarded_at" do
          expect {
            post.discard
          }.to change { post.discarded_at }
        end

        it "sets discarded_at in DB" do
          expect {
            post.discard
          }.to change { post.reload.discarded_at }
        end
      end
    end

    context "discarded Post" do
      let!(:post) { Post.create!(title: "A discarded post", discarded_at: Time.parse('2017-01-01')) }

      it "is included in the default scope" do
        expect(Post.all).to eq([post])
      end

      it "is not included in kept scope" do
        expect(Post.kept).to eq([])
      end

      it "is not included in undiscarded scope" do
        expect(Post.undiscarded).to eq([])
      end

      it "is included in discarded scope" do
        expect(Post.discarded).to eq([post])
      end

      it "should be discarded?" do
        expect(post).to be_discarded
      end

      describe '#discard' do
        it "doesn't change discarded_at" do
          expect {
            post.discard
          }.not_to change { post.discarded_at }
        end

        it "doesn't change discarded_at in DB" do
          expect {
            post.discard
          }.not_to change { post.reload.discarded_at }
        end
      end
    end
  end

  context "with default scope" do
    with_model :WithDefaultScope, scope: :all do
      table do |t|
        t.datetime :discarded_at
        t.timestamps null: false
      end

      model do
        include Discard::Model
        default_scope -> { kept }
      end
    end
    let(:klass) { WithDefaultScope }

    context "an undiscarded record" do
      let!(:record) { klass.create! }

      it "is included in the default scope" do
        expect(klass.all).to eq([record])
      end

      it "is included in kept scope" do
        expect(klass.kept).to eq([record])
      end

      it "is included in undiscarded scope" do
        expect(klass.undiscarded).to eq([record])
      end

      it "is included in with_discarded scope" do
        expect(klass.with_discarded).to eq([record])
      end

      it "is not included in discarded scope" do
        expect(klass.discarded).to eq([])
      end
    end

    context "a discarded record" do
      let!(:record) { klass.create!(discarded_at: Time.current) }

      it "is not included in the default scope" do
        expect(klass.all).to eq([])
      end

      it "is not included in kept scope" do
        expect(klass.kept).to eq([])
      end

      it "is not included in undiscarded scope" do
        expect(klass.kept).to eq([])
      end

      it "is not included in discarded scope" do
        # This is not ideal, but I don't want to improve it at the expense of
        # models withot a default scope
        expect(klass.discarded).to eq([])
      end

      it "is included in with_discarded scope" do
        expect(klass.with_discarded).to eq([record])
      end

      it "is included in with_discarded.discarded scope" do
        expect(klass.with_discarded.discarded).to eq([record])
      end
    end
  end

  context "with custom column name" do
    with_model :Post, scope: :all do
      table do |t|
        t.string :title
        t.datetime :deleted_at
        t.timestamps null: false
      end

      model do
        include Discard::Model
        self.discard_column = :deleted_at
      end
    end

    context "an undiscarded Post" do
      let!(:post) { Post.create!(title: "My very first post") }

      it "is included in the default scope" do
        expect(Post.all).to eq([post])
      end

      it "is included in kept scope" do
        expect(Post.kept).to eq([post])
      end

      it "is included in undiscarded scope" do
        expect(Post.undiscarded).to eq([post])
      end

      it "is not included in discarded scope" do
        expect(Post.discarded).to eq([])
      end

      it "should not be discarded?" do
        expect(post).not_to be_discarded
      end

      describe '#discard' do
        it "sets discarded_at" do
          expect {
            post.discard
          }.to change { post.deleted_at }
        end

        it "sets discarded_at in DB" do
          expect {
            post.discard
          }.to change { post.reload.deleted_at }
        end
      end
    end

    context "discarded Post" do
      let!(:post) { Post.create!(title: "A discarded post", deleted_at: Time.parse('2017-01-01')) }

      it "is included in the default scope" do
        expect(Post.all).to eq([post])
      end

      it "is not included in kept scope" do
        expect(Post.kept).to eq([])
      end

      it "is not included in undiscarded scope" do
        expect(Post.undiscarded).to eq([])
      end

      it "is included in discarded scope" do
        expect(Post.discarded).to eq([post])
      end

      it "should be discarded?" do
        expect(post).to be_discarded
      end

      describe '#discard' do
        it "doesn't change discarded_at" do
          expect {
            post.discard
          }.not_to change { post.deleted_at }
        end

        it "doesn't change discarded_at in DB" do
          expect {
            post.discard
          }.not_to change { post.reload.deleted_at }
        end
      end
    end
  end

end
