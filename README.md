# Discard

Soft deletes for ActiveRecord done right.

![](http://i.hawth.ca/u/ron-swanson-computer-trash.gif)

## Why should I use this?

I've maintained the [paranoia](https://github.com/rubysherpas/paranoia) gem
along with [Ben Morgan](https://github.com/BenMorganIO) and [Ryan
Bigg](http://github.com/radar), the original author.

Paranoia, along with it's predecessor
[acts_as_paranoid](https://github.com/ActsAsParanoid/acts_as_paranoid) both
attempt to solve the problem of wanting to hide records from users.They imitate
deletes by setting a column and add a default scope to the model. This requires
some ActiveRecord hackery, and leads to some surprising and hard to maintain
behaviour.

These libraries have a number of issues:

* A default scope is added to hide soft-deleted records, which necessitates
  adding `.with_deleted` to associations or anywhere soft-deleted records
  should be found.
* `delete` is overridden (`really_delete` will actually delete the record)
* `destroy` is overridden (`really_destroy` will actually delete the record)
* `dependent: :destroy` associations are deleted when performing soft-destroys,
  requiring any dependent records to also be `acts_as_paranoid` to avoid losing data.
* Default scopes make ActiveRecord slow.

There are some use cases where these behaviours make sense, but more often,
developers are looking to just hide some records, or mark them as inactive.

Discard takes a different approach. It avoids hooking into ActiveRecord at all,
and instead simply provides convenience methods for discarding (hiding),
restoring, and viewing records.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'discard'
```

And then execute:

    $ bundle

## Usage

(This doesn't work yet. Doing some readme driven development)

**Declare a record as discardable**

Declare the record as being discardable

``` ruby
class Post
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

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/jhawthorn/discard.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

