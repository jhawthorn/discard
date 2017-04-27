# Discard

Soft deletes for ActiveRecord done right.

<img src="http://i.hawth.ca/u/ron-swanson-computer-trash.gif" width="800" />

## What does this do?

A simple ActiveRecord mixin to add conventions for flagging records as discarded.

## Why should I use this?

I've been worked with and have helped maintain
[paranoia](https://github.com/rubysherpas/paranoia) for a while. I'm convinced
it does the wrong thing for most cases.

Paranoia and
[acts_as_paranoid](https://github.com/ActsAsParanoid/acts_as_paranoid) both
attempt to emulate deletes by setting a column and adding a default scope on the
model. This requires some ActiveRecord hackery, and leads to some surprising
and awkward behaviour.

* A default scope is added to hide soft-deleted records, which necessitates
  adding `.with_deleted` to associations or anywhere soft-deleted records
  should be found.
  * A workaround for associations is `belongs_to :child, -> { with_deleted }`,
    but this is broken for joins or eager-loading.
* `delete` is overridden (`really_delete` will actually delete the record)
* `destroy` is overridden (`really_destroy` will actually delete the record)
* `dependent: :destroy` associations are deleted when performing soft-destroys,
  requiring any dependent records to also be `acts_as_paranoid` to avoid losing data.
* Soft deleting a record will destroy any `dependent: :destroy` associations. Probably not what you want!
  * This leads to all dependent records also needing to be `acts_as_paranoid`

There are some use cases where these behaviours make sense, but more often,
developers are looking to just hide some records, or mark them as inactive.

Discard takes a different approach. It doesn't override any ActiveRecord
methods and instead simply provides convenience methods for discarding
(hiding), restoring, and accessing records.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'discard'
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


``` ruby
class AddDiscardableToPost < ActiveRecord::Migration[5.0]
  def up
    add_column :posts, :discarded_at, :datetime
  end
end
```


**Discard a record**
```
Post.all             # => [#<Post id: 1, ...>]
Post.kept            # => [#<Post id: 1, ...>]
Post.discarded       # => []

@post = Post.first   # => #<Post id: 1, ...>
@post.discard!
@post.discarded?     # => true
@post.discarded_at   # => 2017-04-18 18:49:49 -0700

Post.all             # => [#<Post id: 1, ...>]
Post.kept            # => []
Post.discarded       # => [#<Post id: 1, ...>]
```

**From a controller**

Unlike its predecessors, controller actions will need a small modification to
discard records instead of deleting them.

``` ruby
def destroy
  @post.discard
  redirect_to users_url, notice: "Post removed"
end
```

**Associations**

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
  has_many :posts

  include Discard::Model
  scope :kept, -> { undiscarded.joins(:posts).merge(Post.kept) }
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


**Default scope**

It's usually undesirable to add a default scope. It will take more time and
cause more headaches in the lon run. But if you know you need it, I believe you
❤, and it's easy to add yourself.

``` ruby
class Post < ActiveRecord::Base
  include Discard::Model
  default_scope -> { kept }
end

Post.all                       # Only kept posts
Post.with_discarded            # All Posts
Post.with_discarded.discarded  # Only discarded posts
```


## Non-features

* Restoring records (this will probably be added)
* Discarding dependent records (this will likely be added)
* Callbacks (this will probably be added)
* Special handling of AR counter cache columns - The counter cache counts the total number of records, both kept and discarded.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/jhawthorn/discard.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

## Acknowledgments

* [Ben Morgan](https://github.com/BenMorganIO) who has done a great job maintaining paranoia
* [Ryan Bigg](http://github.com/radar), the original author of paranoia (and many things), as a simpler replacement of acts_as_paranoid
* All paranoia users and contributors
