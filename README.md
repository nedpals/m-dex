# m-dex

Rest API for [MangaDex](https://mangadex.org). Written on Crystal.

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     m-dex:
       github: nedpals/m-dex
   ```

2. Run `shards install`

## Usage
```crystal
require "m-dex"

mangadex = Mdex::Client.new

# Get genre
mangadex.genre(8)

# Get manga info
mangadex.manga(12345)

# Get groups
mangadex.group(18)

# Get user profile
mangadex.user(22407)
```


## Development

### Roadmap
- [x] Manga Info page
- [x] Updates*1
- [x] Genre*1
- [x] Group Info*2
- [x] User Info*2
- [x] Search*3&4

(*) - See **Issues** section.

### Issues
1. Pagination is yet to be implemented.
2. Loading of group and user-curated chapters is still in progress.
3. Search won't work unless a user logs in. Authentication will be implemented as soon as possible.
4. Search is limited right to displaying fields.

## Contributing

1. Fork it (<https://github.com/nedpals/m-dex/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [your-name-here](https://github.com/nedpals) - creator and maintainer
