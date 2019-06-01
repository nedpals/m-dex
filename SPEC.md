# M-dex JSON API Specification
**First revision: 06/01/2019**

This specification will serve as a guide for contributors when testing and designing new measures for generating data in the M-dex library.

## Terms
1. **Entity** - A single data object with its own defined characteristics.
2. **Response** - Received data after you request/send an information to the server. 
3. **Field Name** - Another term for a field key.

Words with a caret symbol (^) in the end denotes optional fields. While words in `code` format are the actual names of the field or the data type obviously.

## Type/Field-specific
### Arrays
- Use plural words for field names. (Ex: An array of `group` should be `groups`)
- Alternatively, you can also connect `_array` in the end. (Like `page_array`)

### Bools
- Field names must be prefixed with `is_` or `has_` (Example: `is_info_paginated`).

### Floating points
- For now, floating point numbers must be converted to `String` for unknown reasons in the compiler.

### ID's
- Should be `Int32`-typed.
- Do not prefix the field. Only `id` for semantic reasons.

### Integers / Numbers
- Numbers representing as bools (like `0` for `false` and vice-versa) must be converted into `Bool`s.
- Comma-delimitted numbers must be unformatted into machine-readable number. (`1,943` => `1943`)

### Links
- Return the full URL. (`/user/1` must return `https://mangadex.org/user/1`)
- Field name must be the website name. If none specified, use "Link" instead as default value.

### Rich Text Format
- Convert rich text formats into safe HTML strings.

## For paginated results
Results must return a `previous` and `next` link fields for ease of use.

## Manga
A manga entity contains the following information related to the specific manga. A manga object must have the following:

- `id` (Unique two to six-digit `Int32` identifier for the manga)
- `cover_image` (Image URL of the manga's front cover)
- `title` (Title/name of the manga)
- `description^` (HTML-formatted text of the description of the manga)
- `alternate_names^` (Alternate names of the manga)
    - returns an array of `String`s
- `author^` (Author of the manga)
- `artist^` (Artist of the manga)
- `demographics^` (Demographics targeted by the manga)
    - returns an array of `genre` entity.
- `genre^` (Genre of the manga)
    - returns an array of `genre` entity.
- `format^` (Formats used by the manga)
    - returns an array of `genre` entity.
- `theme^` (Themes of the manga)
    - returns an array of `genre` entity.
- `official_links^` (Official link URLs of the manga)
- `retail_links^` (Retail link URLs of the manga)
- `links^` (Links related to the manga)
- `bayesian_rating^` (Rating of the manga based on the estimated mean of population)
- `mean_rating^` (Average rating of the manga)
- `users_rated^` (Number of users who rated the manga)
- `views^` (Pageviews of the manga title page)
- `follows^` (Number of people who followed the manga)
- `status^` (Status of the manga)
- `chapters^` (Shows first 100 chapters of the manga)
    - returns an array of `chapter` entity.
- `total_chapters^` (Total number of chapters in a manga)
- `chapter_list_results_per_page^` (Displays the maximum number of chapters per page)
- `chapter_list_pages^` (Maximum pages of chapter list results in a manga.)


## Chapter
A chapter entity contains the following information to the specific chapter of the manga. A chapter object must have the following:

- `id` (Unique two to six-digit `Int32` identifier for the chapter)
- `title` (Title of the chapter)
- `chapter_number` (Number of the chapter)
- `volume` (Volume number of the chapter)
- `link` (Canonical link to the chapter)
- `date_uploaded` (Date when the chapter was uploaded)
- `translation_groups` (List of groups who worked on the chapter)
    - returns an array of `group` entity.
- `uploader` (User who uploaded the chapter) (Returns a `user` entity)
- `views` (Pageviews of the chapter page)

There have been specific fields important for fetching pages of the chapter:
- `manga_id` (ID of the parent manga.)
- `image_hash` (Hash identification for locating the chapter images.)
- `chapter_length^` (Number of pages in a chapter)
- `server_url` (Server used in serving the chapter's images)
- `pages` (Scanned images of the chapter which all return the filename of the images)
- `is_long_strip` (Detects whether if the pages are in long strip form)

## Genre
A genre entity contains the following information related to the specific genre. The genre can be anything that is a category such as demographics, themes, and etc. A genre object must have the following
- `id` (Unique one-digit `Int32` identifier for the genre)
- `name` (Name of the genre)
- `description^` (HTML-formatted text of the description of the genre)
- `manga_array` (List of mangas grouped into that specific genre)
    - returns an array of `manga` entity

## Group
A group entity contains the following information to the specific translation group. A group object must have the following:
- `id` (Unique two to five-digit `Int32` identifier for the group)
- `link` (Link to the group's profile)
- `name` (Name of the group)
- `cover_image^` (Image URL of the group's cover image)
- `alternate_names^` (Alternate names of the group)
    - returns an array of `String`s
- `views^` (Pageviews of the group profile page)
- `follows^` (Number of follows of the group)
- `total_chapters^` (Total chapters created by the group)
- `links^` (Group's links)
- `upload_delay^` (Delay interval for releasing chapters created by the group.)
- `leader` (Group's leader) (Must return a `user` entity object)
- `members` (Members involved in the group)
    - returns an array of `user` entity.
- `description` (HTML-formatted text of the group's description)

## User
A user entity contains the following information/metadata related to the specific user. A user object must have the following:

- `id` (Unique two to five-digit `Int32` identifier for the user)
- `link` (Link to the user's profile)
- `username` (Literally the user's name)
- `avatar_url^` (Image URL to the user's avatar / display image)
- `level^` (User's position / rank in the website)
- `date_joined^` (Complete sign-up date of the user)
- `last_active^` (Humanized relative date/time when the user last logged in to the site)
- `website^` (Website link of the user)
- `groups^` (Groups joined by the user)
    - returns an array of `group` entity.
- `views^` (Pageviews of the user profile)
- `uploaded_chapters^` (Chapters uploaded by the user)
    - returns an array of `chapter` entity.
- `biography^` (HTML-formatted biography/description of the user)

