# Discard [![Build Status](https://travis-ci.org/jhawthorn/discard.svg?branch=master)](https://travis-ci.org/jhawthorn/discard)

Soft deletes for ActiveRecord done right.

<img src="http://i.hawth.ca/u/ron-swanson-computer-trash.gif" width="800" />

## What does this do?

A simple ActiveRecord mixin to add conventions for flagging records as discarded.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'discard', '~> 1.2'
```

And then execute:

    $ bundle

## Usage

**Declare a record as discardable**

Declare the record as being discardable

``` ruby
class Post < ActiveRecord::Base
  include Discard::Model
end
```

You can either generate a migration using:
```
rails generate migration add_discarded_at_to_posts discarded_at:datetime:index
```

or create one yourself like the one below:
``` ruby
class AddDiscardToPosts < ActiveRecord::Migration[5.0]
  def change
    add_column :posts, :discarded_at, :datetime
    add_index :posts, :discarded_at
  end
end
```


#### Discard a record

```ruby
Post.all             # => [#<Post id: 1, ...>]
Post.kept            # => [#<Post id: 1, ...>]
Post.discarded       # => []

post = Post.first   # => #<Post id: 1, ...>
post.discard        # => true
post.discard!       # => Discard::RecordNotDiscarded: Failed to discard the record
post.discarded?     # => true
post.undiscarded?   # => false
post.kept?          # => false
post.discarded_at   # => 2017-04-18 18:49:49 -0700

Post.all             # => [#<Post id: 1, ...>]
Post.kept            # => []
Post.discarded       # => [#<Post id: 1, ...>]
```

***From a controller***

Controller actions need a small modification to discard records instead of deleting them. Just replace `destroy` with `discard`.

``` ruby
def destroy
  @post.discard
  redirect_to users_url, notice: "Post removed"
end
```


#### Undiscard a record

```ruby
post = Post.first   # => #<Post id: 1, ...>
post.undiscard      # => true
post.undiscard!     # => Discard::RecordNotUndiscarded: Failed to undiscard the record
post.discarded_at   # => nil
```

***From a controller***

```ruby
def update
  @post.undiscard
  redirect_to users_url, notice: "Post undiscarded"
end
```

#### Working with associations

Under paranoia, soft deleting a record will destroy any `dependent: :destroy`
associations. Probably not what you want! This leads to all dependent records
also needing to be `acts_as_paranoid`, which makes restoring awkward: paranoia
handles this by restoring any records which have their deleted_at set to a
similar timestamp. Also, it doesn't always make sense to mark these records as
deleted, it depends on the application.

A better approach is to simply mark the one record as discarded, and use SQL
joins to restrict finding these if that's desired.

For example, in a blog comment system, with `Post`s and `Comment`s, you might
want to discard the records independently. A user's comment history could
include comments on deleted posts.

``` ruby
Post.kept # SELECT * FROM posts WHERE discarded_at IS NULL
Comment.kept # SELECT * FROM comments WHERE discarded_at IS NULL
```

Or you could decide that comments are dependent on their posts not being
discarded. Just override the `kept` scope on the Comment model.

``` ruby
class Comment < ActiveRecord::Base
  belongs_to :post

  include Discard::Model
  scope :kept, -> { undiscarded.joins(:post).merge(Post.kept) }

  def kept?
    undiscarded? && post.kept?
  end
end

Comment.kept
# SELECT * FROM comments
#    INNER JOIN posts ON comments.post_id = posts.id
# WHERE
#    comments.discarded_at IS NULL AND
#       posts.discarded_at IS NULL
```

SQL databases are very good at this, and performance should not be an issue.

In both of these cases restoring either of these records will do right thing!


#### Default scope

It's usually undesirable to add a default scope. It will take more effort to
work around and will cause more headaches. If you know you need a default scope, it's easy to add yourself ❤.

``` ruby
class Post < ActiveRecord::Base
  include Discard::Model
  default_scope -> { kept }
end

Post.all                       # Only kept posts
Post.with_discarded            # All Posts
Post.with_discarded.discarded  # Only discarded posts
```

#### Custom column

If you're migrating from paranoia, you might want to continue using the same
column.

``` ruby
class Post < ActiveRecord::Base
  include Discard::Model
  self.discard_column = :deleted_at
end
```

#### Callbacks

Callbacks can be run before, after, or around the discard and undiscard operations.
A likely use is discarding or deleting associated records (but see "Working with associations" for an alternative).

``` ruby
class Comment < ActiveRecord::Base
  include Discard::Model
end

class Post < ActiveRecord::Base
  include Discard::Model

  has_many :comments

  after_discard do
    comments.discard_all
  end

  after_undiscard do
    comments.undiscard_all
  end
end
```

*Warning:* Please note that callbacks for save and update are run when discarding/undiscarding a record


#### Performance tuning
`discard_all` and `undiscard_all` is intended to behave like `destroy_all` which has callbacks, validations, and does one query per record. If performance is a big concern, you may consider replacing it with:

`scope.update_all(discarded_at: Time.current)`
or
`scope.update_all(discarded_at: nil)`

#### Working with Devise

A common use case is to apply discard to a User record. Even though a user has been discarded they can still login and continue their session.
If you are using Devise and wish for discarded users to be unable to login and stop their session you can override Devise's method.

```ruby
class User < ActiveRecord::Base
  def active_for_authentication?
    super && !discarded?
  end
end
```

## Non-features

* Special handling of AR counter cache columns - The counter cache counts the total number of records, both kept and discarded.
* Recursive discards (like AR's dependent: destroy) - This can be avoided using queries (See "Working with associations") or emulated using callbacks.
* Recursive restores - This concept is fundamentally broken, but not necessary if the recursive discards are avoided.

## Extensions

Discard provides the smallest subset of soft-deletion features that we think are useful to all users of the gem. We welcome the addition of gems that work with Discard to provide additional features.

- [discard-rails-observers](https://github.com/pelargir/discard-rails-observers) integrates discard with the [rails-observers gem](https://github.com/rails/rails-observers)

## Why not paranoia or acts_as_paranoid?

I've worked with and have helped maintain
[paranoia](https://github.com/rubysherpas/paranoia) for a while. I'm convinced
it does the wrong thing for most cases.

Paranoia and
[acts_as_paranoid](https://github.com/ActsAsParanoid/acts_as_paranoid) both
attempt to emulate deletes by setting a column and adding a default scope on the
model. This requires some ActiveRecord hackery, and leads to some surprising
and awkward behaviour.

* A default scope is added to hide soft-deleted records, which necessitates
  adding `.with_deleted` to associations or anywhere soft-deleted records
  should be found. :disappointed:
  * Adding `belongs_to :child, -> { with_deleted }` helps, but doesn't work for
    joins and eager-loading [before Rails 5.2](https://github.com/rubysherpas/paranoia/issues/355)
* `delete` is overridden (`really_delete` will actually delete the record) :unamused:
* `destroy` is overridden (`really_destroy` will actually delete the record) :pensive:
* `dependent: :destroy` associations are deleted when performing soft-destroys :scream:
  * requiring any dependent records to also be `acts_as_paranoid` to avoid losing data. :grimacing:

There are some use cases where these behaviours make sense: if you really did
want to _almost_ delete the record. More often developers are just looking to
hide some records, or mark them as inactive.

Discard takes a different approach. It doesn't override any ActiveRecord
methods and instead simply provides convenience methods and scopes for
discarding (hiding), restoring, and querying records.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

## Contributing

Please consider filing an issue with the details of any features you'd like to see before implementing them. Discard is feature-complete and we are only interested in adding additional features that won't require substantial maintenance burden and that will benefit all users of the gem. We encourage anyone that needs additional or different behaviour to either create their own gem that builds off of discard or implement a new package with the different behaviour.

Discard is very simple and we like it that way. Creating your own clone or fork with slightly different behaviour may not be that much work!

If you find a bug in discard, please report it! We try to keep up with any issues and keep the gem running smoothly for everyone! You can report issues [here](https://github.com/jhawthorn/discard/issues).

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

## Acknowledgments

* [Ben Morgan](https://github.com/BenMorganIO) who has done a great job maintaining paranoia
* [Ryan Bigg](http://github.com/radar), the original author of paranoia (and many things), as a simpler replacement of acts_as_paranoid
* All paranoia users and contributors
