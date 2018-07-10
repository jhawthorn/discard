# frozen_string_literal: true

RSpec.describe Discard::Model do
  shared_examples "a Post model" do
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

      describe '#discard!' do
        it "sets discarded_at" do
          expect {
            post.discard!
          }.to change { post.discarded_at }
        end

        it "sets discarded_at in DB" do
          expect {
            post.discard!
          }.to change { post.reload.discarded_at }
        end
      end

      describe '#undiscard' do
        it "doesn't change discarded_at" do
          expect {
            post.undiscard
          }.not_to change { post.discarded_at }
        end

        it "doesn't change discarded_at in DB" do
          expect {
            post.undiscard
          }.not_to change { post.reload.discarded_at }
        end
      end

      describe '#undiscard!' do
        it "raises Discard::RecordNotUndiscarded" do
          expect {
            post.undiscard!
          }.to raise_error(Discard::RecordNotUndiscarded)
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

      describe '#discard!' do
        it "raises Discard::RecordNotDiscarded" do
          expect {
            post.discard!
          }.to raise_error(Discard::RecordNotDiscarded)
        end
      end

      describe '#undiscard' do
        it "clears discarded_at" do
          expect {
            post.undiscard
          }.to change { post.discarded_at }.to(nil)
        end

        it "clears discarded_at in DB" do
          expect {
            post.undiscard
          }.to change { post.reload.discarded_at }.to(nil)
        end
      end

      describe '#undiscard!' do
        it "clears discarded_at" do
          expect {
            post.undiscard!
          }.to change { post.discarded_at }.to(nil)
        end

        it "clears discarded_at in DB" do
          expect {
            post.undiscard!
          }.to change { post.reload.discarded_at }.to(nil)
        end
      end
    end
  end

  context "with simple Post model" do
    with_model :Post, scope: :all do
      table do |t|
        t.string :title
        t.datetime :discarded_at
        t.timestamps null: false
      end

      model do
        include Discard::Model
        validates_presence_of :title
      end
    end

    it_behaves_like "a Post model"

    it 'does not persist an invalid record' do
      post = Post.new(title: nil)
      expect(post.valid?).to eq(false)
      expect { post.discard! }.to raise_error(Discard::RecordNotDiscarded)
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

      describe '#undiscard' do
        it "doesn't change discarded_at" do
          expect {
            post.undiscard
          }.not_to change { post.deleted_at }
        end

        it "doesn't change discarded_at in DB" do
          expect {
            post.undiscard
          }.not_to change { post.reload.deleted_at }
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

      describe '#undiscard' do
        it "clears discarded_at" do
          expect {
            post.undiscard
          }.to change { post.deleted_at }.to(nil)
        end

        it "clears discarded_at in DB" do
          expect {
            post.undiscard
          }.to change { post.reload.deleted_at }.to(nil)
        end
      end
    end
  end

  context "with a unique index" do
    with_model :Post, scope: :all do
      table do |t|
        t.string :title, null: false
        t.datetime :discarded_at
        t.integer :discarded_at_unique, null: false, default: 0
        t.timestamps null: false

        t.index [:title, :discarded_at_unique], name: 'discarded_index', unique: true
      end

      model do
        include Discard::Model
        self.discard_unique_column = :discarded_at_unique
      end
    end

    let!(:post) { Post.create!(title: "My very first post") }

    it "supports unique indexes" do
      expect { Post.create!(title: "My very first post") }.to raise_error ActiveRecord::RecordNotUnique
      post.discard!
      expect(post.reload.discarded_at_lock).to eq(post.id)
      expect { Post.create!(title: "My very first post") }.to_not raise_error
    end

    it "can undiscard" do
      post.discard
      post.undiscard
      expect(post.reload.discarded_at_lock).to eq(0)
    end

    it_behaves_like "a Post model"
  end

  describe '.discard_all' do
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

    let!(:post) { Post.create!(title: "My very first post") }
    let!(:post2) { Post.create!(title: "A second post") }

    it "can discard all posts" do
      expect {
        Post.discard_all
      }.to   change { post.reload.discarded? }.to(true)
        .and change { post2.reload.discarded? }.to(true)
    end

    it "can discard a single post" do
      Post.where(id: post.id).discard_all
      expect(post.reload).to be_discarded
      expect(post2.reload).not_to be_discarded
    end

    it "can discard no records" do
      Post.where(id: []).discard_all
      expect(post.reload).not_to be_discarded
      expect(post2.reload).not_to be_discarded
    end

    context "through a collection" do
      with_model :Comment, scope: :all do
        table do |t|
          t.belongs_to :user
          t.datetime :discarded_at
          t.timestamps null: false
        end

        model do
          include Discard::Model
        end
      end

      with_model :User, scope: :all do
        table do |t|
          t.timestamps null: false
        end

        model do
          include Discard::Model

          has_many :comments
        end
      end

      it "can be discard all related posts" do
        user1 = User.create!
        user2 = User.create!

        2.times { user1.comments.create! }
        2.times { user1.comments.create! }

        user1.comments.discard_all

        expect(user1.comments).to all(be_discarded)
        expect(user2.comments).to all(be_undiscarded)
      end
    end
  end

  describe '.undiscard_all' do
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

    let!(:post) { Post.create!(title: "My very first post", discarded_at: Time.now) }
    let!(:post2) { Post.create!(title: "A second post", discarded_at: Time.now) }

    it "can undiscard all posts" do
      expect {
        Post.undiscard_all
      }.to   change { post.reload.discarded? }.to(false)
        .and change { post2.reload.discarded? }.to(false)
    end

    it "can undiscard a single post" do
      Post.where(id: post.id).undiscard_all
      expect(post.reload).not_to be_discarded
      expect(post2.reload).to be_discarded
    end

    it "can undiscard no records" do
      Post.where(id: []).undiscard_all
      expect(post.reload).to be_discarded
      expect(post2.reload).to be_discarded
    end
  end

  describe 'discard callbacks' do
    with_model :Post, scope: :all do
      table do |t|
        t.datetime :discarded_at
        t.timestamps null: false
      end

      model do
        include Discard::Model
        before_discard :do_before_discard
        before_save :do_before_save
        after_save :do_after_save
        after_discard :do_after_discard

        def do_before_discard; end
        def do_before_save; end
        def do_after_save; end
        def do_after_discard; end
      end
    end

    def abort_callback
      if ActiveRecord::VERSION::MAJOR < 5
        false
      else
        throw :abort
      end
    end

    let!(:post) { Post.create! }

    it "runs callbacks in correct order" do
      expect(post).to receive(:do_before_discard).ordered
      expect(post).to receive(:do_before_save).ordered
      expect(post).to receive(:do_after_save).ordered
      expect(post).to receive(:do_after_discard).ordered

      expect(post.discard).to be true
      expect(post).to be_discarded
    end

    context 'before_discard' do
      it "can allow discard" do
        expect(post).to receive(:do_before_discard).and_return(true)
        expect(post.discard).to be true
        expect(post).to be_discarded
      end

      it "can prevent discard" do
        expect(post).to receive(:do_before_discard) { abort_callback }
        expect(post.discard).to be false
        expect(post).not_to be_discarded
      end

      describe '#discard!' do
        it "raises Discard::RecordNotDiscarded" do
          expect(post).to receive(:do_before_discard) { abort_callback }
          expect {
            post.discard!
          }.to raise_error(Discard::RecordNotDiscarded)
        end
      end
    end
  end

  describe 'undiscard callbacks' do
    with_model :Post, scope: :all do
      table do |t|
        t.datetime :discarded_at
        t.timestamps null: false
      end

      model do
        include Discard::Model
        before_undiscard :do_before_undiscard
        before_save :do_before_save
        after_save :do_after_save
        after_undiscard :do_after_undiscard

        def do_before_undiscard; end
        def do_before_save; end
        def do_after_save; end
        def do_after_undiscard; end
      end
    end

    def abort_callback
      if ActiveRecord::VERSION::MAJOR < 5
        false
      else
        throw :abort
      end
    end

    let!(:post) { Post.create! discarded_at: Time.now }

    it "runs callbacks in correct order" do
      expect(post).to receive(:do_before_undiscard).ordered
      expect(post).to receive(:do_before_save).ordered
      expect(post).to receive(:do_after_save).ordered
      expect(post).to receive(:do_after_undiscard).ordered

      expect(post.undiscard).to be true
      expect(post).not_to be_discarded
    end

    context 'before_undiscard' do
      it "can allow undiscard" do
        expect(post).to receive(:do_before_undiscard).and_return(true)
        expect(post.undiscard).to be true
        expect(post).not_to be_discarded
      end

      it "can prevent undiscard" do
        expect(post).to receive(:do_before_undiscard) { abort_callback }
        expect(post.undiscard).to be false
        expect(post).to be_discarded
      end

      describe '#undiscard!' do
        it "raises Discard::RecordNotDiscarded" do
          expect(post).to receive(:do_before_undiscard) { abort_callback }
          expect {
            post.undiscard!
          }.to raise_error(Discard::RecordNotUndiscarded)
        end
      end
    end
  end
end
