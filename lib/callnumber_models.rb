## frozen_string_literal: true

require 'simple_solr_client'

require 'delegate'

class SolrDocWrapper < SimpleDelegator

  attr_accessor :exact_match
  def initialize(solrdoc, exact_match: false)
    @solrdoc = solrdoc
    __setobj__ @solrdoc
    @exact_match = exact_match
  end
end


class CallnumberRangeQuery

  SSC          = SimpleSolrClient::Client.new 'http://search-prep:8025/solr'
  CN_CORE      = SSC.core('callnumbers')
  CATALOG_CORE = SSC.core('biblio')


  attr_reader :callnumber, :cn_core, :catalog_core, :rows
  attr_accessor :query, :filters, :results, :key, :page

  def initialize(callnumber:,
                 key: nil,
                 page: 0,
                 cn_core: CN_CORE,
                 catalog_core: CATALOG_CORE,
                 query: '*:*',
                 filters: [],
                 rows: 30)
    @callnumber   = callnumber
    @page         = page
    @cn_core      = cn_core
    @catalog_core = catalog_core
    @query        = query
    @filters      = filters
    @rows         = rows
    @results      = nil
    @key          = key
  end

  def clone_to(klass, **kwargs)
    args = {
      callnumber:   self.callnumber,
      key:          self.key,
      page:         self.page,
      cn_core:      self.cn_core,
      catalog_core: self.catalog_core,
      query:        self.query,
      filters:      self.filters,
      rows:         self.rows
    }.merge(kwargs)

    klass.new(**args)
  end

  def base_query_args
    args = {
      rows: rows,
      q:    query,
      fq:   filters
    }
    args
  end

  def sort
    'id asc'
  end

  def range
    raise "Must implement 'range' in subclass"
  end

  def query_args
    args        = base_query_args.dup
    args[:fq]   = filters + [range]
    args[:sort] = sort
    args
  end

  def bib_ids
    cn_key_query.docs.map { |h| h['bib_id'] }
  end

  def cn_key_query
    @cn_key_query ||= CNKeyQuery.new(cn_core, query_args)
  end

  def catalog_docs_from_ids
    return [] if bib_ids.empty?
    q                    = 'id:(' + bib_ids.join(" OR ") + ')'
    @catalog_docs_by_ids ||= catalog_core.get('select', q: q, rows: bib_ids.size)['response']['docs']
  end

  def reorder_docs(documents)
    documents
  end

  def docs
    @results ||= begin
                   cdocs = catalog_docs_from_ids
                   bib_ids.map do |bib_id|
                     d = cdocs.find { |x| x['id'] == bib_id }
                     puts "Can't find doc for #{bib_id}" unless d
                     d
                   end
                 end.map{|x| SolrDocWrapper.new(x)}
    reorder_docs(@results)
  end
end


class NextPage < CallnumberRangeQuery

  def next_page
    self.clone_to(NextPage, key: next_page_key, page: page + 1)
  end

  def previous_page
    self.clone_to(NextPage, key: previous_page_key, page: page - 1)
  end

  def url_args
    {
      page: page,
      callnumber: callnumber,
      key: key
    }
  end

  def sort
    "id asc"
  end

  def range
    %Q(id:{"#{key}" TO *])
  end

  def next_page_key
    cn_key_query.last_key
  end

  def previous_page_key
    cn_key_query.first_key
  end

end

class FirstPage < NextPage

  def previous_two_results
    @ppc ||= clone_to(PreviousPage, key: callnumber, rows: 2)
  end

  def exact_matches
    @epc ||= clone_to(ExactPage, key: callnumber)
  end

  def next_page_key
    next_results.next_page_key
  end

  def previous_page_key
    previous_two_results.previous_page_key
  end

  def next_results
    puts "Starting with #{rows} rows"
    rows_needed = rows - exact_matches.docs.size - 2
    puts "Rows needed: #{rows_needed}"
    if exact_matches.docs.empty?
      newkey = callnumber
    else
      newkey = exact_matches.next_page_key
    end
    puts "Using #{newkey} as new key"
    @npc ||= clone_to(NextPage, key: newkey, rows: rows_needed)
  end

  def docs
    d = previous_two_results.docs
    e = exact_matches.docs
    if e.empty?
      e = [:placeholder]
    end
    n = next_results.docs
    d + e + n
  end

end


class PreviousPage < NextPage
  def sort
    "id desc"
  end

  def range
    %Q(id:[* TO "#{key}"})
  end

  def reorder_docs(documents)
    documents.reverse
  end

end


class ExactPage < NextPage

  # Not really a range in this case...
  def range
    r= %Q(callnumber:"#{callnumber}")
    puts r
    r
  end

  def docs
    d = super
    d.each {|sd| sd.exact_match = true}
  end
end

class CNKeyQuery

  attr_reader :cn_core, :resp, :query_args

  def initialize(cn_core, query_args)
    @cn_core    = cn_core
    @query_args = query_args
  end

  def docs
    @docs ||= get_docs
  end

  def get_docs
    puts "CNKeyQuery args are " + query_args.to_s
    @resp = cn_core.get('select', query_args)
    @resp['response']['docs']
  end

  def first_key
    docs.first['id']
  end

  def last_key
    docs.last['id']
  end

end
