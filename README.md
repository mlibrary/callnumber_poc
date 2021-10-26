# Callnumber browse proof-of-concept

This is a simple Rails app as a PoC of callnumber browse.

On the one hand, it works. On the other...

To try it out:

* Make sure you're on the library VPN, since it talks to search-prep
* Clone this repo and `bundle install`
* `rails server` to fire it up
* ...and go to the URL

Note that the number of rows is currently set to 5 just because having
a long screen of callnumbers makes debugging so much harder. Also, the 
index on search-prep only has Alma stuff in it (no Zephir), which 
shouldn't make a difference for this use case. 

## How it works

We start with custom java code that allows Solr to manipulate the 
callnumbers as they come such that they index in a way that sorts 
reasonably well. 

(Note that the hard part was getting all the solr bits of it working; if 
we decide we want to tweak the sort-index algorithm for the callnumbers it 
should be pretty easy.)

I then created a side-core that has three columns:
  * callnumber (must be LC)
  * bib_id
  * id: a sortable-key made of the callnumber/bib_id pair

It's populated by taking _all_ of the LC callnumbers from a record (from 
the 852s, falling back to the 050 if it can't find anything else) and 
putting in one row per callnumber. Thus records with multiple callnumbers 
in 852s will appear in more than one place in the list.

To populate a new side core from scratch takes a little over an hour, but 
if we 
put datestamps on our catalog records indicating when they were indexed, 
it should be possible to just grab the record that were indexed "today" and 
buzz through them one at a time. We could also potentially build this into 
the regular indexing process, but it'd be a little messy (probably have to 
build a special writer and call it from an `each_record` block in the 
traject code). 

## What's in the URL?

* `callnumber` is the original search callnumber. It's used to populate 
  the search box and drive the search on the first page
* `page` starts at 0 and goes up/down every time you hit next/previous. 
  When page = 0, we know we're on a "first page" and need to do that whole 
  "Your search would appear here" bit.
* `key` is the callnumber/bib_id combination key created for the 
  callnumber side-core. 

## What works, however ugly-ly

* Takes into account semantics of callnumber numeric part (e.g., browsing 
  on 'PA1' won't get you the 'PA 1000' area)
* Deals with finding the edges of the list via `#has_previous_page` and
  `#has_next_page`
* Figures out if you have an exact match and puts in a placeholder if not

## What the code needs

* Refactoring. Lots of it. Everything is currently stuck in one big file 
  with a bunch of classes in it (`lib/callnumber_models.rb`)
* The script that creates the side-core is dumb as a thumb, and doesn't 
  even deal with solr errors correctly. It could benefit from perhaps 
  parallelization, and certainly from using a traject-like writer that 
  takes care of all the hard stuff. 
* Someone to talk me through naming. The names are awful.