# J-Trainer

A jeopardy training app.

## features

Display all jeopardy clues

### todo

* Fix pagination of clues
  * hotfix: clues?page=n
* use an API instead of static file to fetch clues
  * [rithmschool jeopardy](https://github.com/rithmschool/jeopardy-api)
* Implement [turbo frames](~/Documents/notes/ruby/rails/turbo.md) to update clues without refreshing the page
  * probably want to have a static page for session that has at least three frames:
    * clues
    * responses
    * session stats
